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
  neutron_env = pkgs.python3.buildEnv.override {
    extraLibs = [ neutron ];
  };

  utils_env = pkgs.buildEnv {
    name = "utils";
    paths = [ neutron_env ];
  };

  neutronConf = pkgs.writeText "neutron.conf" ''
    [DEFAULT]
    core_plugin = ml2
    debug = false
    # File name for the paste.deploy config for api service (string value)
    api_paste_config = ${neutron}/etc/neutron/api-paste.ini
    transport_url = rabbit://openstack:openstack@controller
    log_dir = /var/log/neutron

    [agent]
    root_helper = "/run/current-system/sw/bin/sudo ${neutron}/bin/neutron-rootwrap ${rootwrapConf}"

    [oslo_concurrency]
    lock_path = /var/lib/neutron/tmp
  '';

  openvswitchConf = pkgs.writeText "openvswitch_agent.ini" ''
    [ovs]
    bridge_mappings = provider:br-provider
    ovsdb_connection = unix:/run/openvswitch/db.sock

    [securitygroup]
    firewall_driver = openvswitch
    enable_security_group = true
  '';

  rootwrapConf = pkgs.callPackage ../generic/rootwrap-conf.nix {
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
    openvswitchConfig = mkOption {
      default = openvswitchConf;
      description = ''
        The Neutron OpenVSwitch config.
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
          d = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
        "/var/lock/neutron" = {
          d = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
        "/var/lib/neutron" = {
          d = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
        "/etc/neutron/plugins/ml2" = {
          d = {
            group = "neutron";
            mode = "0755";
            user = "neutron";
          };
        };
      };
    };

    security.sudo.enable = true;
    security.sudo.extraConfig = ''
      neutron ALL = (root) NOPASSWD: ${neutron}/bin/neutron-rootwrap ${rootwrapConf} *
    '';

    virtualisation.vswitch = {
      enable = true;
      resetOnStart = true;
    };

    systemd.services.neutron-openvswitch-agent = {
      description = "OpenStack Neutron OpenVSwitch Agent";
      after = [
        "network.target"
        "ovsdb.service"
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
        conntrack-tools
      ];
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "neutron-openvswitch-agent-pre.sh" ''
          ${pkgs.openvswitch}/bin/ovs-vsctl add-br br-provider
          ${pkgs.openvswitch}/bin/ovs-vsctl add-port br-provider ${cfg.providerInterface}
        '';
        ExecStart = pkgs.writeShellScript "neutron-openvswitch-agent.sh" ''
          ${neutron}/bin/neutron-openvswitch-agent --config-file=${cfg.config} --config-file=${cfg.openvswitchConfig}
        '';
      };
    };
  };
}
