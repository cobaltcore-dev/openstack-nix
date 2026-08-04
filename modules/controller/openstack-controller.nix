{
  nova,
  neutron,
  keystone,
  glance,
  placement,
  horizon,
  cinder,
  python-openstackclient,
}:
{
  config,
  lib,
  pkgs,
  ...
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

  adminEnvScript = pkgs.writeShellScript "openstack-admin-env" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") adminEnv
    )
  );

  databaseSetupScript = pkgs.writeShellScript "database-setup.sh" ''
    export PATH=${lib.makeBinPath [ pkgs.mariadb ]}:$PATH

    # Keystone
    mysql -N -e "drop database keystone;" || true
    mysql -N -e "create database keystone;" || true
    mysql -N -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'keystone';"
    mysql -N -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'keystone';"

    # Glance
    mysql -N -e "drop database glance;" || true
    mysql -N -e "create database glance;" || true
    mysql -N -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'glance';"
    mysql -N -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'glance';"

    # Cinder
    mysql -N -e "drop database cinder;" || true
    mysql -N -e "create database cinder;" || true
    mysql -N -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'cinder';"
    mysql -N -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'cinder';"

    # Placement
    mysql -N -e "drop database placement;" || true
    mysql -N -e "create database placement;" || true
    mysql -N -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'placement';"
    mysql -N -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'placement';"

    # Nova
    mysql -N -e "drop database nova_api;" || true
    mysql -N -e "drop database nova;" || true
    mysql -N -e "drop database nova_cell0;" || true
    mysql -N -e "create database nova_api;" || true
    mysql -N -e "create database nova;" || true
    mysql -N -e "create database nova_cell0;" || true

    mysql -N -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';"
    mysql -N -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'nova';"
    mysql -N -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';"
    mysql -N -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'nova';"
    mysql -N -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'nova';"
    mysql -N -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'nova';"

    # Neutron
    mysql -N -e "drop database neutron;" || true
    mysql -N -e "create database neutron;" || true
    mysql -N -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'neutron';"
    mysql -N -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'neutron';"
  '';

  keystonePreStartScript = pkgs.writeShellScript "keystone-all-pre-start.sh" ''
    export PATH=${
      lib.makeBinPath [
        keystone
        pkgs.coreutils
      ]
    }:$PATH

    # Initialise the database
    keystone-manage --config-file ${config.keystone.config} db_sync
    # Set up the keystone's PKI infrastructure
    keystone-manage --config-file ${config.keystone.config} fernet_setup --keystone-user keystone --keystone-group keystone
    keystone-manage --config-file ${config.keystone.config} credential_setup --keystone-user keystone --keystone-group keystone
    chown -R keystone:keystone /etc/keystone
    chown -R keystone:keystone /var/log/keystone
  '';

  keystoneStartScript = pkgs.writeShellScript "keystone-all.sh" ''
    export PATH=${
      lib.makeBinPath [
        keystone
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    exec runuser --user keystone --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    keystone-manage --config-file ${config.keystone.config} bootstrap \
      --bootstrap-password admin\
      --bootstrap-region-id RegionOne
     openstack project create --domain default --description "Service Project" service
    EOF
  '';

  glanceStartScript = pkgs.writeShellScript "glance.sh" ''
    export PATH=${
      lib.makeBinPath [
        glance
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    exec runuser --user glance --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password glance glance
    openstack role add --project service --user glance admin
    openstack role add --user glance --user-domain default --system all reader
    glance-manage --config-file ${config.glance.config} db_sync
    EOF
  '';

  cinderStartScript = pkgs.writeShellScript "cinder.sh" ''
    export PATH=${
      lib.makeBinPath [
        cinder
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    exec runuser --user cinder --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password cinder cinder || true
    openstack role add --project service --user cinder admin  || true
    openstack role add --user cinder --user-domain default --system all reader || true
    cinder-manage --config-file ${config.cinder.config} db sync
    EOF
  '';

  placementStartScript = pkgs.writeShellScript "placement.sh" ''
    export PATH=${
      lib.makeBinPath [
        placement
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    exec runuser --user placement --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password placement placement
    openstack role add --project service --user placement admin
    placement-manage --config-file ${config.placement.config} db sync
    EOF
  '';

  novaStartScript = pkgs.writeShellScript "nova.sh" ''
    export PATH=${
      lib.makeBinPath [
        nova
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    exec runuser --user nova --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password nova nova
    openstack role add --project service --user nova admin
    nova-manage --config-file ${config.nova.config} api_db sync
    nova-manage --config-file ${config.nova.config} cell_v2 map_cell0
    nova-manage --config-file ${config.nova.config} cell_v2 create_cell --name=cell1 --verbose
    nova-manage --config-file ${config.nova.config} db sync
    EOF
  '';

  neutronStartScript = pkgs.writeShellScript "neutron.sh" ''
    export PATH=${
      lib.makeBinPath [
        neutron
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    exec runuser --user neutron --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password neutron neutron
    openstack role add --project service --user neutron admin
    neutron-db-manage --config-file ${config.neutron.config} --config-file ${config.neutron.ml2Config} upgrade head
    EOF
  '';

in
{
  imports = [
    ./generic.nix
    ../generic/controller-host-entry.nix
    (import ./keystone.nix { inherit keystone; })
    (import ./glance.nix { inherit glance; })
    (import ./placement.nix { inherit placement; })
    (import ./nova.nix { inherit nova; })
    (import ./neutron.nix { inherit neutron; })
    (import ./horizon.nix { inherit horizon; })
    (import ./cinder.nix { inherit cinder; }) # only cinder management component
  ];

  options.openstack.production_setup = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether the controller uses a production database setup. When enabled,
      the destructive database setup service is disabled.
    '';
  };

  config = {

    environment.systemPackages = [
      python-openstackclient
    ];

    system.activationScripts.openstack-setup-scripts.text = ''
      install -d -m 0700 /root/os-setup
      install -m 0700 ${adminEnvScript} /root/os-setup/.env
      install -m 0700 ${databaseSetupScript} /root/os-setup/000-database-setup.sh
      install -m 0700 ${keystonePreStartScript} /root/os-setup/001-keystone-all-pre-start.sh
      install -m 0700 ${keystoneStartScript} /root/os-setup/002-keystone-all.sh
      install -m 0700 ${glanceStartScript} /root/os-setup/003-glance.sh
      install -m 0700 ${cinderStartScript} /root/os-setup/003-cinder.sh
      install -m 0700 ${placementStartScript} /root/os-setup/004-placement.sh
      install -m 0700 ${novaStartScript} /root/os-setup/006-nova.sh
      install -m 0700 ${neutronStartScript} /root/os-setup/005-neutron.sh
    '';

    systemd.services.database-setup = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Database setup";
      after = [
        "mysql.service"
        "network.target"
        "uwsgi.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.mariadb ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "/root/os-setup/database-setup.sh";
      };
    };

    systemd.services.keystone-all = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Keystone Daemon";
      after = [ "database-setup.service" ];
      path = [
        keystone
        pkgs.openstackclient
      ];
      environment = adminEnv;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "keystone";
        Group = "keystone";
        Type = "oneshot";
        ExecStartPre = "+/root/os-setup/keystone-all-pre-start.sh";
        ExecStart = "+/root/os-setup/keystone-all.sh";
      };
    };

    systemd.services.glance = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Glance setup";
      after = [ "keystone-all.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        glance
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "glance";
        Group = "glance";
        ExecStart = "+/root/os-setup/glance.sh";
      };
    };

    systemd.services.cinder = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Cinder setup";
      after = [ "keystone-all.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        cinder
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "cinder";
        Group = "cinder";
        ExecStart = "+/root/os-setup/cinder.sh";
      };
    };

    # Placement service can be tested by executing
    # curl http://controller:8778
    # and receive some json with version info as result.
    systemd.services.placement = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Placement setup";
      after = [ "glance.service" ];
      requiredBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        placement
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "placement";
        Group = "placement";
        ExecStart = "+/root/os-setup/placement.sh";
      };
    };

    systemd.services.nova = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Nova setup";
      after = [ "neutron.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        nova
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "nova";
        Group = "nova";
        ExecStart = "+/root/os-setup/nova.sh";
      };
    };

    systemd.services.neutron = {
      description = "OpenStack Neutron setup";
      after = [ "placement.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        neutron
      ];
      serviceConfig = {
        Type = "oneshot";
        User = "neutron";
        Group = "neutron";
        ExecStart = "+/root/os-setup/neutron.sh";
      };
    };
  };
}
