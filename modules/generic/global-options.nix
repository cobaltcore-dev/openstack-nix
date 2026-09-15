{ lib, ... }:
with lib;
{
  options.openstack.controllerHostname = lib.mkOption {
    type = types.str;
    default = "controller";
    description = ''
      Hostname of the OpenStack controller.
    '';
  };

  options.openstack.manual_setup = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to manage OpenStack setup manually. When enabled, automatic
      database setup, OpenStack service bootstrapping, and Cinder storage
      initialization are disabled. Setup must be performed separately.

      This option is meant to allow persistent setups of openstack-nix as
      physical deployments.
    '';
  };

  options.openstack.computeIP = lib.mkOption {
    type = types.str;
    description = ''
      IP address of the compute node, used as Nova's my_ip and as the address
      reached by the serial-console and VNC proxies. This address must already
      be configured on the host; this option does not configure an interface.
    '';
  };

  options.openstack.live_migration_inbound_addr = lib.mkOption {
    default = "10.100.100.1";
    type = types.str;
    description = ''
      My own ip address of the migration network. Usually our internal 100G link.
    '';
  };
}
