{ lib, config, ... }:
with lib;
{
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
