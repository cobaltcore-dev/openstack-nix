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

  options.openstack.controllerIP = lib.mkOption {
    type = types.str;
    description = ''
      IP address of the controller, used by controller services and for the
      configured controller hostname in /etc/hosts. The controller and
      controller.local aliases also resolve to this address.
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

  options.openstack.live_migration_inbound_addr = lib.mkOption {
    default = null;
    type = types.nullOr types.str;
    description = ''
      Address of this compute node on the live migration network. When set,
      configures Nova's libvirt live_migration_inbound_addr. When null, the
      setting is omitted and Nova uses its default.
    '';
  };
}
