{ config, ... }:
{
  imports = [ ./global-options.nix ];

  config = {
    networking.extraHosts = ''
      ${config.openstack.controllerIP} controller controller.local
    '';
  };
}
