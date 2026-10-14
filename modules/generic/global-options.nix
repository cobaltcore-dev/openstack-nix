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
      controller and controller.local entries in /etc/hosts.
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
}
