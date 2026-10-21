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
    www_authenticate_uri  = http://${config.openstack.controllerHostname}:5000/v3
    auth_url = http://${config.openstack.controllerHostname}:5000/v3
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = placement
    password = placement

    [placement_database]
    connection = mysql+pymysql://placement:placement@${config.openstack.controllerHostname}/placement
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
    env = mkOption {
      type = types.listOf types.str;
      default = [
        "PYTHONWARNINGS=ignore::DeprecationWarning"
      ];
      description = ''
        Environment variables passed to the placement uWSGI vassal.
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
          "L+" = {
            argument = "${cfg.config}";
          };
        };
      };
    };

    services.uwsgi = {
      instance.vassals = optionalAttrs cfg.enable {
        placement-api = {
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
          env = cfg.env;
        }
        // optionalAttrs (!config.openstack.manual_setup) {
          # Keystone must start in the same emperor before Placement setup can
          # finish. Wait only in this vassal, using a hook that works as non-root.
          exec-asap = pkgs.writeShellScript "placement-api-wait-for-setup" ''
            for ((attempt = 0; attempt < 300; attempt++)); do
              if test -f /run/placement-setup/ready; then
                exit 0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "Timed out waiting for Placement database setup" >&2
            exit 1
          '';
        };
      };
    };
  };
}
