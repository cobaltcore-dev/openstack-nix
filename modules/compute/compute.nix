{ neutron, nova }:
{ lib, ... }:
{
  imports = [
    ../generic/global-options.nix
    ../generic/controller-host-entry.nix
    (import ./neutron.nix { inherit neutron; })
    (import ./nova.nix { inherit nova; })
  ];

  options.openstack.computeIP = lib.mkOption {
    type = lib.types.str;
    description = ''
      IP address of the compute node, used as Nova's my_ip and as the address
      reached by the serial-console and VNC proxies. This address must already
      be configured on the host; this option does not configure an interface.
    '';
  };
}
