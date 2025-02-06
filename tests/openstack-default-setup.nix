{
  pkgs,
  nixosModules,
}:
let
  adminEnv = {
    OS_USERNAME = "admin";
    OS_PASSWORD = "admin";
    OS_PROJECT_NAME = "admin";
    OS_USER_DOMAIN_NAME = "Default";
    OS_PROJECT_DOMAIN_NAME = "Default";
    OS_AUTH_URL = "http://controller:5000/v3";
    OS_IDENTITY_API_VERSION = "3";
  };

  image = pkgs.fetchurl {
    url = "https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img";
    hash = "sha256-B+RKc+VMlNmIAoUVQDwe12IFXgG4OnZ+3zwrOH94zgA=";
  };

  common =
    { lib, ... }:
    {
      system.stateVersion = lib.trivial.release;

      services.getty.autologinUser = "root";

      networking.extraHosts = ''
        10.0.0.11 controller controller.local
      '';

      networking = {
        useDHCP = false;
        networkmanager.enable = false;
        useNetworkd = true;
        firewall.enable = false;
      };

      environment.systemPackages = [
        pkgs.openstackclient
      ];

      environment.variables = adminEnv;
    };

in
pkgs.nixosTest {
  name = "OpenStack default setup test";

  nodes.controllerVM =
    { ... }:
    {
      imports = [
        common
        nixosModules.controllerModule
      ];

      systemd.services.openstack-create-vm = {
        description = "OpenStack";
        path = [
          pkgs.openstackclient
          pkgs.openssh
        ];
        environment = adminEnv;
        serviceConfig = {
          Type = "simple";
          ExecStart = pkgs.writeShellScript "openstack-create-vm.sh" ''
            set -euxo pipefail

            openstack network create  --share --external \
              --provider-physical-network provider \
              --provider-network-type flat provider

            openstack subnet create --network provider \
              --allocation-pool start=192.168.44.50,end=192.168.44.100 \
              --dns-nameserver 8.8.4.4 --gateway 192.168.44.1 \
              --subnet-range 192.168.44.0/24 provider

            openstack image create --disk-format qcow2 --container-format bare --public --file ${image} cirros
            openstack flavor create --public m1.nano --id auto --ram 256 --disk 0 --vcpus 1

            openstack security group rule create --proto icmp default
            openstack security group rule create --proto tcp --dst-port 22 default

            mkdir -p /root/.ssh/
            ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
            openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

            openstack server create \
              --flavor m1.nano \
              --image cirros \
              --key-name mykey \
              --security-group default test_vm \
              --network provider
          '';
        };
      };

      systemd.network = {
        enable = true;
        wait-online.enable = false;

        networks = {
          eth1 = {
            matchConfig.Name = [ "eth1" ];
            networkConfig = {
              Address = "10.0.0.11/24";
              Gateway = "10.0.0.1";
              DNS = "8.8.8.8";
            };
          };

          eth2 = {
            matchConfig.Name = [ "eth2" ];
            networkConfig = {
              DHCP = "no";
              LinkLocalAddressing = "no";
              KeepConfiguration = "yes";
            };
          };
        };
      };
      virtualisation = {
        cores = 4;
        memorySize = 6144;
        interfaces = {
          eth1 = {
            vlan = 1;
          };
          eth2 = {
            vlan = 2;
          };
        };
      };
    };

  nodes.computeVM =
    { ... }:
    {
      imports = [
        common
        nixosModules.computeModule
      ];

      virtualisation = {
        memorySize = 4096;
        cores = 4;
        interfaces = {
          eth1 = {
            vlan = 1;
          };
          eth2 = {
            vlan = 2;
          };
        };
      };

      systemd.network = {
        enable = true;
        wait-online.enable = false;

        networks = {
          eth1 = {
            matchConfig.Name = [ "eth1" ];
            networkConfig = {
              Address = "10.0.0.39/24";
              Gateway = "10.0.0.1";
              DNS = "8.8.8.8";
            };
          };

          eth2 = {
            matchConfig.Name = [ "eth2" ];
            networkConfig = {
              DHCP = "no";
              LinkLocalAddressing = "no";
              KeepConfiguration = "yes";
            };
          };
        };
      };
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
          if len(net_agents) == 4 and len(compute_nodes) == 1 and compute_nodes[0].get("Host","None") == "computeVM":
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

      start_all()
      controllerVM.wait_for_unit("glance-api.service")
      controllerVM.wait_for_unit("placement-api.service")
      controllerVM.wait_for_unit("neutron-server.service")
      controllerVM.wait_for_unit("nova-scheduler.service")
      controllerVM.wait_for_unit("nova-conductor.service")

      assert wait_for_openstack()

      controllerVM.succeed("systemctl start nova-host-discovery.service")
      controllerVM.wait_for_unit("nova-host-discovery.service")
      controllerVM.succeed("systemctl start openstack-create-vm.service")
      controllerVM.wait_for_unit("openstack-create-vm.service")
      assert wait_for_openstack_vm()

      vm_state = json.loads(controllerVM.succeed("openstack server show test_vm -f json"))

      vm_ip = vm_state["addresses"]["provider"][0]
      assert vm_ip.startswith("192.168.44")

      net_ns = controllerVM.succeed("ip netns list | awk '{ print $1 }'").strip()

      # Ping the OpenStack VM from the controller host. We use the network
      # namespace dedicated for the VM to ping it.
      assert retry_until_succeed(controllerVM, f"ip netns exec {net_ns} ping -c 1 {vm_ip}")
    '';
}
