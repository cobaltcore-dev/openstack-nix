{ barbican }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.barbican;

  barbicanConf = pkgs.writeText "barbican-api.conf" ''
    [DEFAULT]
    log_dir = /var/log/barbican
    transport_url = rabbit://openstack:openstack@controller
    my_ip = controller

    [database]
    connection = mysql+pymysql://barbican:barbican@controller/barbican

    [keystone_authtoken]
    www_authenticate_uri  = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = barbican
    password = barbican
    service_token_roles_required = true
    service_token_roles = admin

    region_name = RegionOne
  '';
in
{
  options.barbican = {
    enable = mkEnableOption "Enable OpenStack Barbican." // {
      default = true;
    };
    config = mkOption {
      default = barbicanConf;
      description = ''
        The Barbican config.
      '';
    };
  };
  config = mkIf cfg.enable {

    users.extraUsers.barbican = {
      group = "barbican";
      isSystemUser = true;
    };
    users.groups.barbican = {
      name = "barbican";
      members = [ "barbican" ];
    };

    systemd.tmpfiles.settings = {
      "10-barbican" = {
        "/var/lib/barbican/" = {
          D = {
            user = "barbican";
            group = "barbican";
            mode = "0755";
          };
        };
        "/var/log/barbican/" = {
          D = {
            user = "barbican";
            group = "barbican";
            mode = "0755";
          };
        };
        "/etc/barbican/barbican-api-paste.ini" = {
          L = {
            argument = "${barbican}/etc/barbican/barbican-api-paste.ini";
          };
        };
        "/etc/barbican/barbican.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
      };
    };

    systemd.services.barbican-worker = {
      description = "OpenStack Barbican Worker Daemon";
      after = [
        "barbican.service"
        "rabbitmq.service"
        "mysql.service"
        "network.target"
      ];
      path = [ barbican ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "barbican";
        Group = "barbican";
        ExecStart = pkgs.writeShellScript "barbican-worker.sh" ''
          barbican-worker
        '';
      };
    };

    systemd.services.barbican-api = {
      description = "OpenStack Barbican API Daemon";
      after = [
        "rabbitmq.service"
        "mysql.service"
        "network.target"
      ];
      path = [ barbican ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "barbican";
        Group = "barbican";
        ExecStart = pkgs.writeShellScript "barbican-api.sh" ''
          .barbican-wsgi-api-wrapped --port 9311
        '';
      };
    };

  };
}
