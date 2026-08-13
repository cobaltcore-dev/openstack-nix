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

  cinderConf = pkgs.writeText "cinder-api.conf" ''
    [DEFAULT]
    transport_url = rabbit://openstack:openstack@controller
    auth_strategy = keystone
    my_ip = controller
    verify_glance_signatures = disabled

    [database]
    connection = mysql+pymysql://cinder:cinder@controller/cinder

    [keystone_authtoken]
    www_authenticate_uri = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
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
          D = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/var/lib/cinder/volumes" = {
          D = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/var/log/cinder/" = {
          D = {
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

    # create systemd service only if running in non production mode (CI/CD setup)
    systemd.services.cinder-api = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Cinder API Daemon";
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
        ExecStart = pkgs.writeShellScript "cinder-api.sh" ''
          .cinder-wsgi-wrapped --port 8776
        '';
      };
      enable = cfg.enable;
    };

    # create uwsgi vassal configuration only in production setup
    services.uwsgi = lib.mkIf (config.openstack.production_setup) {
      instance.vassals.cinder-api = mkIf cfg.enable {
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
          .cinder-scheduler-wrapped
        '';
      };
      enable = cfg.enable;
      environment = cfg.envCinderScheduler;
    };
  };
}
