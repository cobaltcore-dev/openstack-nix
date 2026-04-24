{ openstackPkgs }:
{
  controllerModule = import ./controller/openstack-controller.nix {
    inherit (openstackPkgs)
      nova
      neutron
      keystone
      glance
      horizon
      cinder
      barbican
      ;
    placement = openstackPkgs.openstack-placement;
  };

  computeModule = import ./compute/compute.nix { inherit (openstackPkgs) neutron nova; };

  storageModule = import ./storage/cinder-storage-node.nix { inherit (openstackPkgs) cinder; };

  testModules = import ./testing { };
}
