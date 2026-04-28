{
  pkgs,
  nixosModules,
}:
pkgs.nixosTest {
  name = "OpenStack default setup test";

  nodes.controllerVM =
    { ... }:
    {
      imports = [
        nixosModules.controllerModule
        nixosModules.testModules.testController
      ];
    };

  nodes.computeVM =
    { ... }:
    {
      imports = [
        nixosModules.computeModule
        nixosModules.testModules.testCompute
      ];
    };

  nodes.storageVM =
    { ... }:
    {
      imports = [
        nixosModules.storageModule
        nixosModules.testModules.testStorage
      ];
    };

  testScript =
    { ... }:
    ''
      import json
      import time

      def retry_until_succeed(machine, cmd, retries = 10):
        for i in range(retries):
          print(f"Retrying command until success '{cmd}'. {i + 1}/{retries} retries")
          time.sleep(1)
          status, _ = machine.execute(cmd)
          if status == 0:
            return True
        return False

      def print_logfile(machine, filepath):
        _, out = controllerVM.execute(f"cat {filepath}")
        print(f"Printing log of: {filepath}")
        print(out)

      def wait_for_openstack():
        for i in range(120):
          print(f"Waiting for openstack network agents and compute nodes to be present ... {i + 1}/120 sec")
          time.sleep(1)
          status, out = controllerVM.execute("openstack network agent list -f json")
          if status != 0:
            continue
          net_agents = json.loads(out)
          status, out = controllerVM.execute("openstack compute service list --service nova-compute -f json")
          if status != 0:
            continue
          compute_nodes = json.loads(out)
          status, out = controllerVM.execute("openstack volume service list -f json")
          if status != 0:
            continue
          storage_nodes = json.loads(out)
          if len(storage_nodes) == 2 and len(net_agents) == 4 and len(compute_nodes) == 1 and compute_nodes[0].get("Host","None") == "computeVM":
            return True
        return False

      def wait_for_openstack_vm():
        for i in range(30):
          print(f"Waiting for openstack server to be active ... {i + 1}/30 sec")
          time.sleep(1)
          status, out = controllerVM.execute("openstack server list -f json")
          if status != 0:
            continue
          vms = json.loads(out)
          if len(vms) == 1 and vms[0]["Status"] == "ACTIVE":
            return True
          elif len(vms) == 1 and vms[0]["Status"] == "ERROR":
            print(out)
            print_logfile(controllerVM, "/var/log/nova/.nova-manage-wrapped.log")
            print_logfile(controllerVM, "/var/log/nova/.nova-scheduler-wrapped.log")
            print_logfile(controllerVM, "/var/log/nova/.nova-api-wrapped.log")
            print_logfile(controllerVM, "/var/log/nova/.nova-conductor-wrapped.log")
            print_logfile(controllerVM, "/var/log/neutron/.neutron-server-wrapped.log")
            print_logfile(controllerVM, "/var/log/neutron/.neutron-openvswitch-agent-wrapped.log")
            print_logfile(controllerVM, "/var/log/neutron/.neutron-dhcp-agent-wrapped.log")
            return False
        return False

      def wait_for_network_namespace():
        for i in range(30):
          print(f"Waiting for network namespace to appear ... {i +1}/30 sec")
          time.sleep(1)
          net_ns = controllerVM.succeed("ip netns list | awk '{ print $1 }'").strip()
          if net_ns != "":
            return net_ns
        return ""


      start_all()
      controllerVM.wait_for_unit("glance-api.service")
      controllerVM.wait_for_unit("placement-api.service")
      controllerVM.wait_for_unit("neutron-server.service")
      controllerVM.wait_for_unit("nova-scheduler.service")
      controllerVM.wait_for_unit("nova-conductor.service")

      # check all services on storageVM
      ## tgtd is only used in LVM setup
      ## storageVM.wait_for_unit("tgtd.service")
      storageVM.wait_for_unit("nfs-server.service")
      storageVM.wait_for_unit("cinder-volume.service")

      assert wait_for_openstack()

      controllerVM.succeed("systemctl start nova-host-discovery.service")
      controllerVM.wait_for_unit("nova-host-discovery.service")
      controllerVM.succeed("systemctl start openstack-create-vm.service")
      controllerVM.wait_for_unit("openstack-create-vm.service")
      assert wait_for_openstack_vm()

      vm_state = json.loads(controllerVM.succeed("openstack server show test_vm -f json"))

      vm_ip = vm_state["addresses"]["provider"][0]
      assert vm_ip.startswith("192.168.44")

      net_ns = wait_for_network_namespace()
      assert net_ns != ""

      # Ping the OpenStack VM from the controller host. We use the network
      # namespace dedicated for the VM to ping it.
      assert retry_until_succeed(controllerVM, f"ip netns exec {net_ns} ping -c 1 {vm_ip}", 30)

      # create volume with 4GB
      controllerVM.execute("openstack volume type create --encryption-provider luks --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end nfs-luks")
      controllerVM.execute("openstack volume type set nfs-luks --property volume_backend_name=NFS")
      controllerVM.execute("openstack volume create --size 1 --type nfs-luks test_vol")
      # attach volume to VM
      controllerVM.execute("openstack server add volume test_vm test_vol")

      _status, output = controllerVM.execute("openstack volume show test_vol")
      print(f"openstack volume show test_vol: {output}")
      time.sleep(3)
      _status, output = controllerVM.execute("openstack volume show test_vol")
      print(f"openstack volume show test_vol: {output}")
      time.sleep(3)
      _status, output = controllerVM.execute("openstack volume show test_vol")
      print(f"openstack volume show test_vol: {output}")
      time.sleep(3)
      _status, output = controllerVM.execute("openstack volume show test_vol")
      print(f"openstack volume show test_vol: {output}")

      # wait until volume is attached
      assert retry_until_succeed(controllerVM, "openstack volume show test_vol -f value -c status | grep 'in-use'", 20)

      # add ssh host key to known_hosts
      retry_until_succeed(controllerVM, f"ip netns exec {net_ns} ssh-keyscan {vm_ip} > ~/.ssh/known_hosts", 60)

      # passwordless ssh login should work if the metadata service is running and nova can access it
      ## check on controllerVM
      ## neutron.conf
      ## [DEFAULT]
      ## metadata_proxy_shared_secret = secret
      ##
      ## nova.conf
      ## [neutron]
      ## service_metadata_proxy = true
      ## metadata_proxy_shared_secret = secret

      assert retry_until_succeed(controllerVM, f"ip netns exec {net_ns} ssh cirros@{vm_ip} lsblk", 60)
      # check second block device of VM
      status, output = controllerVM.execute(f"ip netns exec {net_ns} ssh cirros@{vm_ip} lsblk | grep vdb")
      output = output.strip()
      print(f"output of lsblk: {output}")
      print(f"exit code of lsblk: {status}")
      assert status == 0
      assert output == "vdb     252:16   0    4G  0 disk"
    '';
}
