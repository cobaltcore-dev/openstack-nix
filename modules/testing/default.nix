{ openstackPkgs }:
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
      imports = [
        ../generic/controller-host-entry.nix
      ];

      config = {
        system.stateVersion = lib.trivial.release;

        services.getty.autologinUser = "root";

        openstack.controllerIP = "10.0.0.11";

        networking = {
          useDHCP = false;
          networkmanager.enable = false;
          useNetworkd = true;
          firewall.enable = false;
        };

        environment.systemPackages = [
          pkgs.openstackclient
          pkgs.openiscsi
          pkgs.sshpass
          openstackPkgs.python-barbicanclient
          openstackPkgs.python-novaclient
        ];

        environment.variables = adminEnv;
        # pw: root
        users.users.root.hashedPassword = lib.mkForce "$y$j9T$HiT/m702z/73g4Dt5RzbW0$b3SaYI1FoyT/ORV/qFR/s9zonJBKDn4p2XKyYM2wp1.";
        users.users.root.hashedPasswordFile = null;

        services.openssh = {
          enable = true;
          ports = [ 22 ];
          settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "yes"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
          };
        };

      };
    };

  portForwarding =
    { config, lib, ... }:
    with lib;
    let
      cfg = config.openstack-testing;
    in
    {
      options.openstack-testing = {
        enable = mkEnableOption "Enable port forwarding." // {
          default = true;
        };
        dashboardHostPort = mkOption {
          default = 8080;
          type = types.port;
          description = ''
            Host port to make the OpenStack dashboard accessible when running
            the OpenStack controller in a VM. Dashboard can be accessed via:
            localhost:<dashboardHostPort>
          '';
        };
        serialProxyHostPort = mkOption {
          default = 6083;
          type = types.port;
          description = ''
            Host port to make the web console feature available for the
            OpenStack dashboard. Changing the value might requires to change
            the configuration of the dashboard.
          '';
        };
        vncProxyHostPort = mkOption {
          default = 6080;
          type = types.port;
          description = ''
            Host port to make the vnc console feature available for the
            OpenStack dashboard. Changing the value might requires to change
            the configuration of the dashboard.
          '';
        };
      };
      config = mkIf cfg.enable {
        virtualisation.forwardPorts = [
          {
            from = "host";
            host.port = cfg.dashboardHostPort;
            guest.port = 80;
          }
          {
            from = "host";
            host.port = cfg.serialProxyHostPort;
            guest.port = 6083;
          }
          {
            from = "host";
            host.port = cfg.vncProxyHostPort;
            guest.port = 6080;
          }
        ];
      };
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
      image_raw = pkgs.runCommand "" { } ''
        ${pkgs.qemu-utils}/bin/qemu-img convert -O raw ${image} $out
      '';
    in
    {
      imports = [
        common
        portForwarding
      ];

      virtualisation = {
        cores = 4;
        memorySize = 6144;
        diskSize = 8192;
        interfaces = {
          eth1 = {
            vlan = 1;
          };
          eth2 = {
            vlan = 2;
          };
        };
        # enable ssh access
        forwardPorts = [
          {
            from = "host";
            host.port = 1122;
            guest.port = 22;
          }
        ];
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

            openstack image create --disk-format raw --container-format bare --public --file ${image_raw} cirros
            openstack flavor create --public m1.nano --id auto --ram 256 --disk 0 --vcpus 1
            # openstack volume qos create --consumer "front-end" --property "total_iops_sec=20000" iops
            # openstack volume qos associate iops __DEFAULT__
            # openstack volume create --image cirros --size 1 --bootable vol

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
              DNS = "8.8.8.8";
            };
          };
          eth1 = {
            matchConfig.Name = [ "eth1" ];
            networkConfig = {
              Address = "10.0.0.11/24";
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

  testStorage =
    { ... }:
    {

      imports = [ common ];

      virtualisation = {
        memorySize = 4096;
        cores = 4;
        diskSize = 4096;
        # add separate disk as LVM backend
        emptyDiskImages = [
          16384 # 16GB
        ];
        interfaces = {
          eth1 = {
            vlan = 1;
          };
          eth2 = {
            vlan = 2;
          };
        };
        # enable ssh access
        forwardPorts = [
          {
            from = "host";
            host.port = 2022;
            guest.port = 22;
          }
        ];
      };

      systemd.network = {
        enable = true;
        wait-online.enable = false;

        networks = {
          eth0 = {
            matchConfig.Name = [ "eth0" ];
            networkConfig = {
              DHCP = "yes";
              LinkLocalAddressing = "yes";
              KeepConfiguration = "yes";
              DNS = "8.8.8.8";
            };
          };

          eth1 = {
            matchConfig.Name = [ "eth1" ];
            networkConfig = {
              Address = "10.0.0.20/24";
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
