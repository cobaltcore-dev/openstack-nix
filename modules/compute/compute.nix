{ neutron, nova }:
{ ... }:
{
  imports = [
    ../generic/global-options.nix
    ../generic/controller-host-entry.nix
    (import ./neutron.nix { inherit neutron; })
    (import ./nova.nix { inherit nova; })
  ];
}
