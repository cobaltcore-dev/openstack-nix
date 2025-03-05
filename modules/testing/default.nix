{ }:
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

  common =
    { pkgs, lib, ... }:
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
{
  testController =
    { pkgs, ... }:
    let
      image = pkgs.fetchurl {
        url = "https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img";
        hash = "sha256-B+RKc+VMlNmIAoUVQDwe12IFXgG4OnZ+3zwrOH94zgA=";
      };
    in
    {
      imports = [ common ];

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
          eth0 = {
            matchConfig.Name = [ "eth0" ];
            networkConfig = {
              DHCP = "yes";
            };
          };
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
    };

  testCompute =
    { ... }:
    {
      imports = [ common ];

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
}
