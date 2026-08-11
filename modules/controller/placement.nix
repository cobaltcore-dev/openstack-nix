{ placement }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.placement;

  placementConf = pkgs.writeText "placement.conf" ''
    [DEFAULT]
    auth_strategy = keystone

    [keystone_authtoken]
    www_authenticate_uri  = http://controller:5000
    auth_url = http://controller:5000
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = placement
    password = placement

    [placement_database]
    connection = mysql+pymysql://placement:placement@controller/placement
  '';
in
{
  options.placement = {
    enable = mkEnableOption "Enable OpenStack Placement." // {
      default = true;
    };
    config = mkOption {
      default = placementConf;
      description = ''
        The Placement config.
      '';
    };
  };
  config = {

    users.extraUsers.placement = {
      group = "placement";
      isSystemUser = true;
    };
    users.groups.placement = {
      name = "placement";
      members = [ "placement" ];
    };

    systemd.tmpfiles.settings = {
      "10-placement" = {
        "/etc/placement/placement.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
      };
    };

    # create systemd service only if running in non production mode (CI/CD setup)
    systemd.services.placement-api = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Placement API Daemon";
      after = [
        "placement.service"
        "rabbitmq.service"
        "mysql.service"
        "network.target"
      ];
      path = [ placement ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "placement";
        Group = "placement";
        ExecStart = pkgs.writeShellScript "placement-api.sh" ''
          # Using the placement-api binary directly warns about that should only
          # be done in development environments. The "correct" way is to use
          # uwsgi, which is kinda tricky in nixos because we would have to start
          # the keystone uwsgi service at first, and placement later. That
          # cannot be expressed in the nixos config AFAIK.
          placement-api --port 8778
        '';
      };
      enable = cfg.enable;
    };

    # create uwsgi vassal configuration only in production setup
    services.uwsgi = lib.mkIf (config.openstack.production_setup) {
      instance.vassals.placement-api = mkIf cfg.enable {
        type = "normal";
        http-socket = "0.0.0.0:8778";
        wsgi-file = "${placement}/bin/.placement-api-wrapped";
        pyargv = "--config-file ${cfg.config}";

        master = true;
        processes = 4;
        enable-threads = true;
        thunder-lock = true;
        lazy-apps = true;
        die-on-term = true;
        vacuum = true;
        need-app = true;
        buffer-size = 65535;

        immediate-uid = "placement";
        immediate-gid = "placement";
      };
    };
  };
}
