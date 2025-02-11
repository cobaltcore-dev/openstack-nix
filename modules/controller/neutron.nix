{ neutron }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.neutron;

  neutronConf = pkgs.writeText "neutron.conf" ''
    [database]
    connection = mysql+pymysql://neutron:neutron@controller/neutron

    [DEFAULT]
    core_plugin = ml2
    service_plugins =
    api_paste_config = ${neutron}/etc/neutron/api-paste.ini
    transport_url = rabbit://openstack:openstack@controller
    auth_strategy = keystone
    notify_nova_on_port_status_changes = true
    notify_nova_on_port_data_changes = true
    log_dir = /var/log/neutron

    [keystone_authtoken]
    www_authenticate_uri = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = neutron
    password = neutron
    service_token_roles_required = true

    # XXX: This only seems to be required when using the admin account when
    # creating servers via "openstack server create ...".
    # See: https://bugs.launchpad.net/nova/+bug/1696082
    service_token_roles = admin

    [nova]
    auth_url = http://controller:5000
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    region_name = RegionOne
    project_name = service
    username = nova
    password = nova

    [oslo_concurrency]
    lock_path = /var/lib/neutron/tmp

    [agent]
    root_helper = "/run/wrappers/bin/sudo ${neutron}/bin/neutron-rootwrap ${rootwrapConf}"
  '';

  ml2Conf = pkgs.writeText "ml2conf.ini" ''
    [ml2]
    type_drivers = flat,vlan
    tenant_network_types =
    mechanism_drivers = openvswitch
    extension_drivers = port_security

    [ml2_type_flat]
    flat_networks = provider
  '';

  # Network debugging in OpenStack
  # * https://wiki.openstack.org/wiki/OpsGuide/Network_Troubleshooting#figure-traffic-route
  openvswitchConf = pkgs.writeText "openvswitch_agent.ini" ''
    [ovs]
    bridge_mappings = provider:br-provider
    ovsdb_connection = unix:/run/openvswitch/db.sock

    [securitygroup]
    enable_security_group = true
    firewall_driver = openvswitch
  '';

  dhcpAgentConf = pkgs.writeText "dhcp_agent.ini" ''
    [DEFAULT]
    interface_driver = openvswitch
    dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
    enable_isolated_metadata = true

    [ovs]
    ovsdb_connection = unix:/run/openvswitch/db.sock
    ovsdb_debug = true
  '';

  metadataAgentConf = pkgs.writeText "metadata_agent.ini" ''
    [DEFAULT]
    nova_metadata_host = controller
    metadata_proxy_shared_secret = neutron_metadata_secret
  '';

  neutron_env = pkgs.python3.buildEnv.override {
    extraLibs = [ neutron ];
  };
  utils_env = pkgs.buildEnv {
    name = "utils";
    paths = with pkgs; [
      neutron_env
      tcpdump
      haproxy
      iproute2
      procps
      openvswitch
      dnsmasq
      iptables
    ];
  };

  rootwrapConf = pkgs.callPackage ../../lib/rootwrap-conf.nix {
    package = neutron_env;
    filterPath = "/etc/neutron/rootwrap.d";
    inherit utils_env;
  };

in
{
  options.neutron = {
    enable = mkEnableOption "Enable OpenStack Neutron." // {
      default = true;
    };
    config = mkOption {
      default = neutronConf;
      description = ''
        The Neutron config.
      '';
    };
    ml2Config = mkOption {
      default = ml2Conf;
      description = ''
        The Neutron ML2 config.
      '';
    };
    openvswitchConfig = mkOption {
      default = openvswitchConf;
      description = ''
        The Neutron OpenVSwitch config.
      '';
    };
    dhcpAgentConfig = mkOption {
      default = dhcpAgentConf;
      description = ''
        The Neutron DHCP agent config.
      '';
    };
    metadataAgentConfig = mkOption {
      default = metadataAgentConf;
      description = ''
        The Neutron metadata agent config.
      '';
    };
    providerInterface = mkOption {
      default = "eth2";
      type = types.str;
      description = ''
        The name of the physical network interface used for the provider
        network.
      '';
    };
  };
  config = mkIf cfg.enable {

    users.extraUsers.neutron = {
      group = "neutron";
      isSystemUser = true;
    };
    users.groups.neutron = {
      name = "neutron";
      members = [ "neutron" ];
    };

    systemd.tmpfiles.settings = {
      "10-neutron" = {
        "/var/log/neutron" = {
          D = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
        "/etc/neutron/neutron.conf" = {
          L = {
            argument = "${cfg.config}";
          };
        };
        "/etc/neutron/plugins/ml2/ml2_conf.ini" = {
          L = {
            argument = "${cfg.ml2Config}";
          };
        };
        "/etc/neutron/plugins/ml2/openvswitch_agent.ini" = {
          L = {
            argument = "${cfg.openvswitchConfig}";
          };
        };
        "/etc/neutron/dhcp_agent.ini" = {
          L = {
            argument = "${cfg.dhcpAgentConfig}";
          };
        };
        "/etc/neutron/metadata_agent.ini" = {
          L = {
            argument = "${cfg.metadataAgentConfig}";
          };
        };
        "/etc/neutron/api-paste.ini" = {
          L = {
            argument = "${neutron}/etc/neutron/api-paste.ini";
          };
        };
        "/var/lock/neutron" = {
          D = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
        "/var/lib/neutron" = {
          D = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
        "/var/lib/neutron/dhcp" = {
          D = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
      };
    };

    systemd.services.neutron-metadata-agent = {
      description = "OpenStack Neutron Metadata Agent";
      after = [
        "network.target"
        "neutron.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ neutron ];
      serviceConfig = {
        ExecStart = ''${neutron}/bin/neutron-metadata-agent --config-file=${cfg.config} --config-file=${cfg.ml2Config}'';
      };
    };

    virtualisation.vswitch = {
      enable = true;
      resetOnStart = true;
    };

    security.sudo.enable = true;
    security.sudo.extraConfig = ''
      neutron ALL = (root) NOPASSWD: ${neutron}/bin/neutron-rootwrap ${rootwrapConf} *
    '';

    systemd.services.neutron-openvswitch-agent = {
      description = "OpenStack Neutron OpenVSwitch Agent";
      after = [
        "network.target"
        "ovsdb.service"
        "neutron.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        sudo
        neutron
        qemu
        bridge-utils
        procps
        iproute2
        dnsmasq
        openvswitch
      ];
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "pre.sh" ''
          ${pkgs.openvswitch}/bin/ovs-vsctl add-br br-provider || true
          ${pkgs.openvswitch}/bin/ovs-vsctl add-port br-provider ${cfg.providerInterface} || true
        '';
        ExecStart = pkgs.writeShellScript "neutron-openvswitch.sh" ''
          ${neutron}/bin/neutron-openvswitch-agent --config-file=${cfg.config} --config-file=${cfg.openvswitchConfig}
        '';
      };
    };

    systemd.services.neutron-server = {
      description = "OpenStack Neutron Networking server";
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
        "neutron.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ neutron ];
      serviceConfig = {
        User = "neutron";
        Group = "neutron";
        Type = "simple";
        ExecStart = pkgs.writeShellScript "neutron-server.sh" ''
          neutron-server --config-file ${cfg.config} --config-file ${cfg.ml2Config}
        '';
        Restart = "on-failure";
        LimitNOFILE = 65535;
        TimeoutStopSec = 15;
      };
    };

    systemd.services.neutron-dhcp-agent = {
      description = "OpenStack Neutron DhcpNetworking server";
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
        "neutron.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        neutron
        utils_env
      ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "neutron-dhcp-agent.sh" ''
          neutron-dhcp-agent --config-file ${cfg.config} --config-file ${cfg.dhcpAgentConfig}
        '';
        Restart = "on-failure";
        LimitNOFILE = 65535;
        TimeoutStopSec = 15;
      };
    };

  };
}
