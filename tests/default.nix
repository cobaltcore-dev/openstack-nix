{
  pkgs,
  nixosModules,
}:
let
  tests = {
    openstack-default-setup = pkgs.callPackage ./openstack-default-setup.nix { inherit nixosModules; };
  };
in
pkgs.lib.mapAttrs (_: v: pkgs.lib.recursiveUpdate v { meta.tag = "nix-integration-test"; }) tests
