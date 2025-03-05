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
  nova_env = pkgs.python3.buildEnv.override {
    extraLibs = [ cfg.novaPackage ];
  };
  utils_env = pkgs.buildEnv {
    name = "utils";
    paths = [ nova_env ];
  };

  novaConf = pkgs.writeText "nova.conf" ''
    [DEFAULT]
    log_dir = /var/log/nova
    lock_path = /var/lock/nova
    state_path = /var/lib/nova
    rootwrap_config = ${rootwrapConf}
    compute_driver = libvirt.LibvirtDriver
    my_ip = 10.0.0.39
    transport_url = rabbit://openstack:openstack@controller

    [api]
    auth_strategy = keystone

    [api_database]
    connection = sqlite:////var/lib/nova/nova_api.sqlite

    [database]
    connection = sqlite:////var/lib/nova/nova.sqlite

    [glance]
    api_servers = http://controller:9292

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

    [libvirt]
    virt_type = kvm

    [neutron]
    auth_url = http://controller:5000
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    region_name = RegionOne
    project_name = service
    username = neutron
    password = neutron

    [os_vif_ovs]
    ovsdb_connection = unix:/run/openvswitch/db.sock

    [oslo_concurrency]
    lock_path = /var/lib/nova/tmp

    [placement]
    region_name = RegionOne
    project_domain_name = Default
    project_name = service
    auth_type = password
    user_domain_name = Default
    auth_url = http://controller:5000/v3
    username = placement
    password = placement

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
    server_listen = 0.0.0.0
    server_proxyclient_address = $my_ip
    novncproxy_base_url = http://controller:6080/vnc_lite.html

    [cells]
    enable = False

    [os_region_name]
    openstack =
  '';

  rootwrapConf = pkgs.callPackage ../../lib/rootwrap-conf.nix {
    package = nova_env;
    filterPath = "/etc/nova/rootwrap.d";
    inherit utils_env;
  };
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
    novaPackage = mkOption {
      default = nova;
      type = types.package;
      description = ''
        The OpenStack Nova package to use.
      '';
    };
    extraPkgs = mkOption {
      default = [ ];
      type = types.listOf types.package;
      description = ''
        Extra packages to be available in the PATH of the nova-compute service
        e.g. an additional hypervisor.
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

    # Nova requires libvirtd and RabbitMQ.
    virtualisation.libvirtd.enable = true;

    systemd.tmpfiles.settings = {
      "10-nova" = {
        "/var/log/nova" = {
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
        "/var/lib/nova" = {
          D = {
            group = "nova";
            mode = "0755";
            user = "nova";
          };
        };
        "/var/lib/nova/instances" = {
          D = {
            group = "nova";
            mode = "0755";
            user = "nova";
          };
        };
      };
    };

    systemd.services.nova-compute = {
      description = "OpenStack Nova Scheduler Daemon";
      after = [
        "rabbitmq.service"
        "network.target"
      ];
      wantedBy = [ "multi-user.target" ];
      path =
        with pkgs;
        [
          sudo
          nova_env
          qemu
        ]
        ++ cfg.extraPkgs;
      environment.PYTHONPATH = "${nova_env}/${pkgs.python3.sitePackages}";
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "nova-compute.sh" ''
          ${cfg.novaPackage}/bin/nova-compute --config-file=${cfg.config}
        '';
      };
    };
  };
}
