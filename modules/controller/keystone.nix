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

  serviceEndPointTemplateConf = pkgs.writeText "default_catalog.templates" ''
    # config for templated.Catalog, using camelCase because I don't want to do
    # translations for keystone compat
    catalog.RegionOne.identity.publicURL = http://controller:5000/v3
    catalog.RegionOne.identity.adminURL = http://controller:5000/v3
    catalog.RegionOne.identity.internalURL = http://controller:5000/v3
    catalog.RegionOne.identity.name = Identity Service

    # fake compute service for now to help novaclient tests work
    catalog.RegionOne.compute.publicURL = http://controller:8774/v2.1
    catalog.RegionOne.compute.adminURL = http://controller:8774/v2.1
    catalog.RegionOne.compute.internalURL = http://controller:8774/v2.1
    catalog.RegionOne.compute.name = Compute Service V2.1

    catalog.RegionOne.image.publicURL = http://controller:9292
    catalog.RegionOne.image.adminURL = http://controller:9292
    catalog.RegionOne.image.internalURL = http://controller:9292
    catalog.RegionOne.image.name = Image Service

    catalog.RegionOne.network.publicURL = http://controller:9696
    catalog.RegionOne.network.adminURL = http://controller:9696
    catalog.RegionOne.network.internalURL = http://controller:9696
    catalog.RegionOne.network.name = Network Service

    catalog.RegionOne.placement.publicURL = http://controller:8778
    catalog.RegionOne.placement.adminURL = http://controller:8778
    catalog.RegionOne.placement.internalURL = http://controller:8778
    catalog.RegionOne.placement.name = Placement Service
  '';

  keystoneConf = pkgs.writeText "keystone.conf" ''
    [DEFAULT]
    log_dir = /var/log/keystone
    [database]
    connection = mysql+pymysql://keystone:keystone@controller/keystone

    [token]
    provider = fernet

    [catalog]
    driver = templated
    template_file = ${serviceEndPointTemplateConf}
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
  };

  config = mkIf cfg.enable {

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
          D = {
            user = "keystone";
            group = "keystone";
            mode = "0755";
          };
        };
        "/var/log/keystone/" = {
          D = {
            user = "keystone";
            group = "keystone";
            mode = "0755";
          };
        };
        # Certain executables e.g. keystone-wsgi-public expect the config file
        # at a default location.
        "/etc/keystone/keystone.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
      };
    };

    services.httpd = {
      enable = true;
      virtualHosts = {
        controller = {
          locations."/".proxyPass = "http://127.0.0.1:5001/";
          listen = [
            {
              ip = "*";
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
      instance.vassals.keystone = {
        type = "normal";
        http-socket = "127.0.0.1:5001";
        buffer-size = 65535;
        immediate-uid = "keystone";
        immediate-gid = "keystone";
        wsgi-file = "${keystone}/bin/.keystone-wsgi-public-wrapped";

        master = true;
        enable-threads = true;
        processes = 4;
        thunder-lock = true;
        lazy-apps = true;
      };
    };
  };
}
