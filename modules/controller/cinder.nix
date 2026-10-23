{ cinder }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.cinder;

  cinderConf = pkgs.writeText "cinder.conf" ''
    [DEFAULT]
    transport_url = rabbit://openstack:openstack@${config.openstack.controllerHostname}
    auth_strategy = keystone
    my_ip = ${config.openstack.controllerIP}
    verify_glance_signatures = disabled

    [database]
    connection = mysql+pymysql://cinder:cinder@${config.openstack.controllerHostname}/cinder

    [keystone_authtoken]
    www_authenticate_uri = http://${config.openstack.controllerHostname}:5000/v3
    auth_url = http://${config.openstack.controllerHostname}:5000/v3
    memcached_servers = ${config.openstack.controllerHostname}:11211
    auth_type = password
    project_domain_name = default
    user_domain_name = default
    project_name = service
    username = cinder
    password = cinder
    service_token_roles_required = true
    service_token_roles = admin

    [oslo_concurrency]
    lock_path = /var/lib/cinder/tmp
  '';
in
{
  options.cinder = {
    enable = mkEnableOption "Enable OpenStack Cinder." // {
      default = true;
    };
    config = mkOption {
      default = cinderConf;
      description = ''
        The Cinder config.
      '';
    };
    cinderPackage = mkOption {
      default = cinder;
      type = types.package;
      description = ''
        The OpenStack Cinder package to use.
      '';
    };
    envCinderApi = mkOption {
      type = types.listOf types.str;
      default = [
        "PYTHONWARNINGS=ignore::DeprecationWarning"
        "PATH=$PATH:/run/current-system/sw/bin"
      ];
      description = ''
        Environment variables passed to the cinder-api uWSGI vassal.
      '';
    };
    envCinderScheduler = mkOption {
      default = {
        PYTHONWARNINGS = "ignore::DeprecationWarning";
      };
      description = ''
        Environment variables passed to the cinder-scheduler systemd unit.
      '';
    };
  };
  config = {

    users.extraUsers.cinder = {
      group = "cinder";
      isSystemUser = true;
    };
    users.groups.cinder = {
      name = "cinder";
      members = [ "cinder" ];
    };

    systemd.tmpfiles.settings = {
      "10-cinder" = {
        "/var/lib/cinder/" = {
          d = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/var/lib/cinder/volumes" = {
          d = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/var/log/cinder/" = {
          d = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/etc/cinder/api-paste.ini" = {
          L = {
            argument = "${cinder}/etc/cinder/api-paste.ini";
          };
        };
        "/etc/cinder/cinder.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
      };
    };

    services.uwsgi = {
      instance.vassals = optionalAttrs cfg.enable {
        cinder-api = {
          type = "normal";
          http-socket = "0.0.0.0:8776";
          wsgi-file = "${cinder}/bin/.cinder-wsgi-wrapped";
          pyargv = "--config-file ${cfg.config}";
          env = cfg.envCinderApi;

          master = true;
          processes = 4;
          enable-threads = true;
          thunder-lock = true;
          lazy-apps = true;
          die-on-term = true;
          vacuum = true;
          need-app = true;
          buffer-size = 65535;

          immediate-uid = "cinder";
          immediate-gid = "cinder";
        }
        // optionalAttrs (!config.openstack.manual_setup) {
          # Keystone must be available in the same emperor before automatic
          # Cinder setup can finish, so only this vassal waits for the schema.
          # As there is no uwsgi mechanism to serialize the vassals, we use a
          # marker file created in the systemd service setup of cinder to wait
          # for first.
          exec-asap = pkgs.writeShellScript "cinder-api-wait-for-setup" ''
            for ((attempt = 0; attempt < 300; attempt++)); do
              if test -f /run/cinder-setup/ready; then
                exit 0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "Timed out waiting for Cinder database setup" >&2
            exit 1
          '';
        };
      };
    };

    systemd.services.cinder-scheduler = {
      description = "OpenStack Cinder Scheduler";
      after = [
        "cinder.service"
        "rabbitmq.service"
        "mysql.service"
        "network.target"
      ];
      path = [ cinder ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "cinder";
        Group = "cinder";
        ExecStart = pkgs.writeShellScript "cinder-scheduler.sh" ''
          .cinder-scheduler-wrapped --config-file ${cfg.config}
        '';
      };
      enable = cfg.enable;
      environment = cfg.envCinderScheduler;
    };
  };
}
