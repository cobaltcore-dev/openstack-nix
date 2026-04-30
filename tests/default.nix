{
  pkgs,
  nixosModules,
  generateRootwrapConf,
  novaPkg,
}:
let
  tests = {
    openstack-default-setup = pkgs.callPackage ./openstack-default-setup.nix {
      inherit nixosModules novaPkg;
    };
    openstack-live-migration = pkgs.callPackage ./openstack-live-migration.nix {
      inherit nixosModules generateRootwrapConf;
    };
  };
in
pkgs.lib.mapAttrs (_: v: pkgs.lib.recursiveUpdate v { meta.tag = "nix-integration-test"; }) tests
