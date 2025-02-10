{ openstackPkgs }:
{
  controllerModule = import ./controller/openstack-controller.nix {
    inherit (openstackPkgs)
      nova
      neutron
      keystone
      glance
      ;
    placement = openstackPkgs.openstack-placement;
  };

  computeModule = import ./compute/compute.nix { inherit (openstackPkgs) neutron nova; };

  testModules = import ./testing { };
}
