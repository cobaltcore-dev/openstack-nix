{ nova }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.nova;

  novaConf = pkgs.writeText "nova.conf" ''
    [api_database]
    connection = mysql+pymysql://nova:nova@controller/nova_api

    [database]
    connection = mysql+pymysql://nova:nova@controller/nova

    [DEFAULT]
    transport_url = rabbit://openstack:openstack@controller:5672/
    my_ip = 10.0.0.11
    log_dir = /var/log/nova
    lock_path = /var/lock/nova
    state_path = /var/lib/nova

    [api]
    auth_strategy = keystone

    [keystone_authtoken]
    www_authenticate_uri = http://controller:5000/
    auth_url = http://controller:5000/
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = nova
    password = nova

    [service_user]
    send_service_user_token = true
    auth_url = http://controller:5000/
    auth_strategy = keystone
    auth_type = password
    project_domain_name = Default
    project_name = service
    user_domain_name = Default
    username = nova
    password = nova

    [vnc]
    enabled = true
    server_listen = $my_ip
    server_proxyclient_address = $my_ip

    [glance]
    api_servers = http://controller:9292

    [oslo_concurrency]
    lock_path = /var/lib/nova/tmp

    [placement]
    project_domain_name = Default
    project_name = service
    auth_type = password
    user_domain_name = Default
    auth_url = http://controller:5000/v3
    username = placement
    password = placement

    [scheduler]
    discover_hosts_in_cells_interval = 300

    [neutron]
    auth_url = http://controller:5000
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    region_name = RegionOne
    project_name = service
    username = neutron
    password = neutron
    service_metadata_proxy = true
    metadata_proxy_shared_secret = neutron_metadata_secret
  '';
in
{
  options.nova = {
    enable = mkEnableOption "Enable OpenStack Nova." // {
      default = true;
    };
    config = mkOption {
      default = novaConf;
      description = ''
        The Nova config.
      '';
    };
  };
  config = mkIf cfg.enable {

    users.extraUsers.nova = {
      group = "nova";
      isSystemUser = true;
    };
    users.groups.nova = {
      name = "nova";
      members = [ "nova" ];
    };

    systemd.tmpfiles.settings = {
      "10-nova" = {
        "/etc/nova/nova.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
        "/etc/nova/api-paste.ini" = {
          L = {
            argument = "${nova}/etc/nova/api-paste.ini";
          };
        };
        "/var/log/nova" = {
          D = {
            group = "nova";
            mode = "0755";
            user = "nova";
          };
        };
        "/var/lib/nova" = {
          D = {
            group = "nova";
            mode = "0755";
            user = "nova";
          };
        };
        "/var/lock/nova" = {
          D = {
            group = "nova";
            mode = "0755";
            user = "nova";
          };
        };
        "/usr/share/novnc" = {
          L = {
            argument = "${pkgs.novnc}/share/webapps/novnc";
          };
        };
      };
    };

    systemd.services.nova-api = {
      description = "OpenStack Compute API";
      after = [
        "nova.service"
        "postgresql.service"
        "mysql.service"
        "keystone.service"
        "rabbitmq.service"
        "ntp.service"
        "network-online.target"
        "local-fs.target"
        "remote-fs.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ nova ];
      serviceConfig = {
        User = "nova";
        Group = "nova";
        Type = "simple";
        ExecStart = pkgs.writeShellScript "nova-api.sh" ''
          nova-api --config-file ${cfg.config}
        '';
      };
    };

    systemd.services.nova-conductor = {
      description = "OpenStack Compute Conductor";
      after = [
        "neutron-server.service"
        "nova.service"
        "glance-api.service"
        "placement-api.service"
        "postgresql.service"
        "mysql.service"
        "keystone.service"
        "rabbitmq.service"
        "ntp.service"
        "network-online.target"
        "local-fs.target"
        "remote-fs.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ nova ];
      serviceConfig = {
        User = "nova";
        Group = "nova";
        Type = "simple";
        ExecStart = pkgs.writeShellScript "nova-conductor.sh" ''
          nova-conductor --config-file ${cfg.config}
        '';
        Restart = "on-failure";
        LimitNOFILE = 65535;
        TimeoutStopSec = 15;
      };
    };

    systemd.services.nova-scheduler = {
      description = "OpenStack Compute Scheduler";
      after = [
        "neutron-server.service"
        "glance-api.service"
        "placement-api.service"
        "nova.service"
        "postgresql.service"
        "mysql.service"
        "keystone.service"
        "rabbitmq.service"
        "ntp.service"
        "network-online.target"
        "local-fs.target"
        "remote-fs.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ nova ];
      serviceConfig = {
        User = "nova";
        Group = "nova";
        Type = "simple";
        ExecStart = pkgs.writeShellScript "nova-scheduler.sh" ''
          nova-scheduler --config-file ${cfg.config}
        '';
        Restart = "on-failure";
        LimitNOFILE = 65535;
        TimeoutStopSec = 15;
      };
    };

    systemd.services.nova-host-discovery = {
      description = "OpenStack Nova Host DB Sync Service";
      requires = [
        "nova-scheduler.service"
        "nova-conductor.service"
        "nova-api.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ ];
      path = [ nova ];
      serviceConfig = {
        User = "nova";
        Group = "nova";
        Type = "exec";
        ExecStart = pkgs.writeShellScript "nova-host-discovery.sh" ''
          set -euxo pipefail
          nova-manage cell_v2 discover_hosts --verbose
        '';
      };
    };

    systemd.services.nova-novncproxy = {
      description = "OpenStack Compute Scheduler";
      after = [
        "neutron-server.service"
        "glance-api.service"
        "placement-api.service"
        "nova.service"
        "postgresql.service"
        "mysql.service"
        "keystone.service"
        "rabbitmq.service"
        "ntp.service"
        "network-online.target"
        "local-fs.target"
        "remote-fs.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ nova ];
      serviceConfig = {
        User = "nova";
        Group = "nova";
        Type = "simple";
        ExecStart = pkgs.writeShellScript "nova-novncproxy.sh" ''
          nova-novncproxy --config-file ${cfg.config}
        '';
        Restart = "on-failure";
        LimitNOFILE = 65535;
        TimeoutStopSec = 15;
      };
    };
  };
}
