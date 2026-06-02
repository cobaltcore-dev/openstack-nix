{
  pkgs,
  nixosModules,
  generateRootwrapConf,
  novaPkg,
  libvirt,
}:
let
  tests = {
    openstack-default-setup = pkgs.callPackage ./openstack-default-setup.nix {
      inherit nixosModules novaPkg libvirt;
    };
    openstack-live-migration = pkgs.callPackage ./openstack-live-migration.nix {
      inherit nixosModules generateRootwrapConf novaPkg;
    };
  };
in
pkgs.lib.mapAttrs (_: v: pkgs.lib.recursiveUpdate v { meta.tag = "nix-integration-test"; }) tests
