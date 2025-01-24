{ neutron, nova }:
{ ... }:
{
  imports = [
    (import ./neutron.nix { inherit neutron; })
    (import ./nova.nix { inherit nova; })
  ];
}
