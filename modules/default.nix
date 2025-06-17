{ openstackPkgs, self }:
{
  controllerModule = import ./controller/openstack-controller.nix {
    inherit (openstackPkgs)
      nova
      neutron
      keystone
      glance
      horizon
      ;
    placement = openstackPkgs.openstack-placement;
  };

  computeModule = import ./compute/compute.nix { inherit (openstackPkgs) neutron nova; };

  testModules = import ./testing { };

  chv-sap = import ./chv-sap.nix { inherit self; };
}
