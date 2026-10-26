{ keystone }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.keystone;

  keystoneConf = pkgs.writeText "keystone.conf" ''
    [DEFAULT]
    log_dir = /var/log/keystone
    [database]
    connection = mysql+pymysql://keystone:keystone@${config.openstack.controllerHostname}/keystone

    [cache]
    enabled = true
    backend = dogpile.cache.memcached
    memcache_servers = 127.0.0.1:11211

    [token]
    provider = fernet

    [catalog]
    driver = sql
  '';
in
{
  options.keystone = {
    enable = mkEnableOption "Enable OpenStack Keystone." // {
      default = true;
    };
    config = mkOption {
      default = keystoneConf;
      description = ''
        The Keystone config.
      '';
    };
    env = mkOption {
      type = types.listOf types.str;
      default = [
        "PYTHONWARNINGS=ignore::DeprecationWarning"
      ];
      description = ''
        Environment variables passed to the Keystone uWSGI vassal.
      '';
    };
  };

  config = {

    users.extraUsers.keystone = {
      group = "keystone";
      isSystemUser = true;
    };
    users.groups.keystone = {
      name = "keystone";
      members = [ "keystone" ];
    };

    systemd.tmpfiles.settings = {
      "10-keystone" = {
        "/var/lib/keystone/" = {
          d = {
            user = "keystone";
            group = "keystone";
            mode = "0755";
          };
        };
        "/var/log/keystone/" = {
          d = {
            user = "keystone";
            group = "keystone";
            mode = "0755";
          };
        };
        # Certain executables e.g. keystone-wsgi-public expect the config file
        # at a default location.
        "/etc/keystone/keystone.conf" = {
          "L+" = {
            argument = "${cfg.config}";
          };
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        ${config.openstack.controllerHostname} = {
          locations."/".proxyPass = "http://127.0.0.1:5001/";
          listen = [
            {
              addr = "*";
              port = 5000;
            }
          ];
        };
      };
    };

    services.uwsgi = {
      enable = true;
      plugins = [ "python3" ];
      capabilities = [
        "CAP_SETGID"
        "CAP_SETUID"
      ];

      instance.type = "emperor";
      instance.vassals.keystone = mkIf cfg.enable {
        type = "normal";
        http11-socket = "127.0.0.1:5001";
        buffer-size = 65535;
        immediate-uid = "keystone";
        immediate-gid = "keystone";
        wsgi-file = "${keystone}/bin/.keystone-wsgi-public-wrapped";

        master = true;
        enable-threads = true;
        processes = 4;
        threads = 4;
        thunder-lock = true;
        lazy-apps = true;
        env = cfg.env;
      };
    };
  };
}
