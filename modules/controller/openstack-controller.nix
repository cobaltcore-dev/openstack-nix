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

  # Keep manual provisioning commands and systemd units on the same store scripts.
  setupCommand =
    name: script:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.systemd
      ];
      text = ''
        if (( EUID != 0 )); then
          echo "Run this command as root." >&2
          exit 1
        fi
        # shellcheck source=/dev/null
        source ${adminEnvScript}
        exec ${script} "$@"
      '';
    };

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

    mysql -N -e "FLUSH PRIVILEGES;"
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
      --bootstrap-password admin \
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

  options.openstack.manual_setup = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to manage OpenStack setup manually. When enabled, automatic
      database setup, OpenStack service bootstrapping, and Cinder storage
      initialization are disabled. Setup must be performed separately.
    '';
  };

  config = {

    environment.systemPackages = [
      (setupCommand "openstack-database-setup" databaseSetupScript)
      (setupCommand "openstack-keystone-pre-setup" keystonePreStartScript)
      (setupCommand "openstack-keystone-setup" keystoneStartScript)
      (setupCommand "openstack-glance-setup" glanceStartScript)
      (setupCommand "openstack-cinder-setup" cinderStartScript)
      (setupCommand "openstack-placement-setup" placementStartScript)
      (setupCommand "openstack-nova-setup" novaStartScript)
      (setupCommand "openstack-neutron-setup" neutronStartScript)
      python-openstackclient
    ];

    systemd.services.database-setup = lib.mkIf (!config.openstack.manual_setup) {
      description = "OpenStack Database setup";
      after = [
        "mysql.service"
        "network.target"
        "uwsgi.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.mariadb ];
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        ExecStart = "${databaseSetupScript}";
      };
    };

    systemd.services.keystone-all = lib.mkIf (!config.openstack.manual_setup) {
      description = "OpenStack Keystone Daemon";
      after = [ "database-setup.service" ];
      path = [
        keystone
        pkgs.openstackclient
      ];
      environment = adminEnv;
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = false;
      serviceConfig = {
        User = "keystone";
        Group = "keystone";
        RemainAfterExit = true;
        Type = "oneshot";
        ExecStartPre = "+${keystonePreStartScript}";
        ExecStart = "+${keystoneStartScript}";
      };
    };

    systemd.services.glance = lib.mkIf (!config.openstack.manual_setup) {
      description = "OpenStack Glance setup";
      after = [ "keystone-all.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        glance
      ];
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        User = "glance";
        Group = "glance";
        ExecStart = "+${glanceStartScript}";
      };
    };

    systemd.services.cinder = lib.mkIf (!config.openstack.manual_setup) {
      description = "OpenStack Cinder setup";
      after = [ "keystone-all.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        cinder
      ];
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        User = "cinder";
        Group = "cinder";
        ExecStart = "+${cinderStartScript}";
      };
    };

    # Placement service can be tested by executing
    # curl http://controller:8778
    # and receive some json with version info as result.
    systemd.services.placement = lib.mkIf (!config.openstack.manual_setup) {
      description = "OpenStack Placement setup";
      after = [ "glance.service" ];
      requiredBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        placement
      ];
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        User = "placement";
        Group = "placement";
        ExecStart = "+${placementStartScript}";
      };
    };

    systemd.services.nova = lib.mkIf (!config.openstack.manual_setup) {
      description = "OpenStack Nova setup";
      after = [ "neutron.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.openstackclient
        nova
      ];
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        User = "nova";
        Group = "nova";
        ExecStart = "+${novaStartScript}";
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
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        User = "neutron";
        Group = "neutron";
        ExecStart = "+${neutronStartScript}";
      };
    };
  };
}
