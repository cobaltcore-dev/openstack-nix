{
  pkgs,
  nixosModules,
}:
{
  openstack-default-setup = pkgs.callPackage ./openstack-default-setup.nix { inherit nixosModules; };
}
