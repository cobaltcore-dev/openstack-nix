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
      python-openstackclient
      designate
      ;
    placement = openstackPkgs.openstack-placement;
  };

  computeModule = import ./compute/compute.nix { inherit (openstackPkgs) neutron nova; };

  storageModule = import ./storage/cinder-storage-node.nix { inherit (openstackPkgs) cinder; };

  knotDesignateModule = import ./knot-designate.nix;

  testModules = import ./testing { inherit (openstackPkgs) python-openstackclient; };
}
