{ config, lib, ... }:
{
  imports = [ ./global-options.nix ];

  config = {
    networking.extraHosts = ''
      ${config.openstack.controllerIP} ${
        lib.concatStringsSep " " (
          lib.unique [
            config.openstack.controllerHostname
            "controller"
            "controller.local"
          ]
        )
      }
    '';
  };
}
