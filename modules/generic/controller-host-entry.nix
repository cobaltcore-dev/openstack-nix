{ lib, config, ... }:
with lib;
{
  options.openstack = {
    controllerIP = mkOption {
      type = types.str;
      default = "10.0.0.11";
      description = ''
        IP address of the controller. Will be used to make a /etc/hosts entry
        to make the controller available via "controller".
      '';
    };
  };

  config = {
    networking.extraHosts = ''
      ${config.openstack.controllerIP} controller controller.local
    '';
  };
}
