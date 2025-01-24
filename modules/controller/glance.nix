{ glance }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.glance;

  glanceConf = pkgs.writeText "glance-api.conf" ''
    [DEFAULT]
    enabled_backends=fs:file

    [database]
    connection = mysql+pymysql://glance:glance@controller/glance

    [keystone_authtoken]
    www_authenticate_uri  = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = glance
    password = glance

    [paste_deploy]
    flavor = keystone

    [glance_store]
    default_backend = fs

    [fs]
    filesystem_store_datadir = /var/lib/glance/images/

    [oslo_limit]
    auth_url = http://controller:5000
    auth_type = password
    user_domain_id = default
    username = glance
    system_scope = all
    password = glance

    region_name = RegionOne
  '';
in
{
  options.glance = {
    enable = mkEnableOption "Enable OpenStack Glance." // {
      default = true;
    };
    config = mkOption {
      default = glanceConf;
      description = ''
        The Glance config.
      '';
    };
  };
  config = mkIf cfg.enable {

    users.extraUsers.glance = {
      group = "glance";
      isSystemUser = true;
    };
    users.groups.glance = {
      name = "glance";
      members = [ "glance" ];
    };

    systemd.tmpfiles.settings = {
      "10-glance" = {
        "/var/lib/glance/" = {
          D = {
            user = "glance";
            group = "glance";
            mode = "0755";
          };
        };
        "/var/lib/glance/images" = {
          D = {
            user = "glance";
            group = "glance";
            mode = "0755";
          };
        };
        "/etc/glance/glance-api.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
        "/etc/glance/glance-api-paste.ini" = {
          L = {
            argument = "${glance}/etc/glance/glance-api-paste.ini";
          };
        };
        "/etc/glance/schema-image.json" = {
          L = {
            argument = "${./schema-image.json}";
          };
        };
      };
    };

    systemd.services.glance-api = {
      description = "OpenStack Glance API Daemon";
      after = [
        "glance.service"
        "rabbitmq.service"
        "mysql.service"
        "network.target"
      ];
      path = [ glance ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "glance";
        Group = "glance";
        ExecStart = pkgs.writeShellScript "exec.sh" ''
          glance-api --config-file=${cfg.config} --config-file=/etc/glance/glance-api-paste.ini
        '';
      };
    };

    services.uwsgi = {
      instance.vassals.glance = {
        socket-timeout = 10;
        http-auto-chunked = true;
        http-chunked-input = true;
        http-raw-body = true;
        chmod-socket = 666;
        lazy-apps = true;
        add-header = "Connection: close";
        buffer-size = 65535;
        thunder-lock = true;
        enable-threads = true;
        exit-on-reload = true;
        die-on-term = true;
        master = true;
        processes = 4;
        http-socket = "127.0.0.1:60999";
        type = "normal";
        immediate-uid = "glance";
        immediate-gid = "glance";
        wsgi-file = "${glance}/bin/.glance-wsgi-api-wrapped";
      };
    };
  };
}
