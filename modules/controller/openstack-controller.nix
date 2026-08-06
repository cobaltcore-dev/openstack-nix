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

  databaseCleanupScript = pkgs.writeShellScript "database-cleanup.sh" ''
    export PATH=${lib.makeBinPath [ pkgs.mariadb ]}:$PATH
    mariadb -N -e "drop database keystone;" || true
    mariadb -N -e "drop database glance;" || true
    mariadb -N -e "drop database cinder;" || true
    mariadb -N -e "drop database placement;" || true
    mariadb -N -e "drop database nova_api;" || true
    mariadb -N -e "drop database nova;" || true
    mariadb -N -e "drop database nova_cell0;" || true
    mariadb -N -e "drop database neutron;" || true
  '';

  databaseSetupScript = pkgs.writeShellScript "database-setup.sh" ''
    export PATH=${lib.makeBinPath [ pkgs.mariadb ]}:$PATH

    # Keystone
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS keystone;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'keystone'@'%' IDENTIFIED BY 'keystone';"
    mariadb -N -e "ALTER USER 'keystone'@'%' IDENTIFIED BY 'keystone';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%';"

    # Glance
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS glance;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'glance'@'%' IDENTIFIED BY 'glance';"
    mariadb -N -e "ALTER USER 'glance'@'%' IDENTIFIED BY 'glance';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%';"

    # Cinder
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS cinder;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'cinder'@'%' IDENTIFIED BY 'cinder';"
    mariadb -N -e "ALTER USER 'cinder'@'%' IDENTIFIED BY 'cinder';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%';"

    # Placement
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS placement;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'placement'@'%' IDENTIFIED BY 'placement';"
    mariadb -N -e "ALTER USER 'placement'@'%' IDENTIFIED BY 'placement';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%';"

    # Nova
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS nova_api;"
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS nova;"
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS nova_cell0;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'nova'@'%' IDENTIFIED BY 'nova';"
    mariadb -N -e "ALTER USER 'nova'@'%' IDENTIFIED BY 'nova';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%';"

    # Neutron
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS neutron;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'neutron'@'%' IDENTIFIED BY 'neutron';"
    mariadb -N -e "ALTER USER 'neutron'@'%' IDENTIFIED BY 'neutron';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%';"

    # fix mariadb permissions
    mariadb -N -e "delete from mysql.user where user = ''';"

    mariadb -N -e "FLUSH PRIVILEGES;"
  '';

  keystonePreStartScript = pkgs.writeShellScript "keystone-all-pre-start.sh" ''
    export PATH=${
      lib.makeBinPath [
        keystone
        pkgs.coreutils
      ]
    }:$PATH

    set -euxo pipefail

    # Initialise the database
    keystone-manage --config-file ${config.keystone.config} db_sync
    # Set up the keystone's PKI infrastructure
    keystone-manage --config-file ${config.keystone.config} fernet_setup --keystone-user keystone --keystone-group keystone
    keystone-manage --config-file ${config.keystone.config} credential_setup --keystone-user keystone --keystone-group keystone
    chown -R keystone:keystone /etc/keystone
    chown -R keystone:keystone /var/log/keystone

    systemctl restart uwsgi.service
  '';

  keystoneStartScript = pkgs.writeShellScript "keystone-all.sh" ''
    export PATH=${
      lib.makeBinPath [
        keystone
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    source /root/os-setup/.env

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

    systemctl stop glance-api.service

    source /root/os-setup/.env

    exec runuser --user glance --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password glance glance
    openstack role add --project service --user glance admin
    openstack role add --user glance --user-domain default --system all reader
    glance-manage --config-file ${config.glance.config} db_sync
    EOF

    systemctl start glance-api.service
  '';

  cinderStartScript = pkgs.writeShellScript "cinder.sh" ''
    export PATH=${
      lib.makeBinPath [
        cinder
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    systemctl stop cinder-api.service cinder-scheduler.service

    source /root/os-setup/.env

    exec runuser --user cinder --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password cinder cinder || true
    openstack role add --project service --user cinder admin  || true
    openstack role add --user cinder --user-domain default --system all reader || true
    cinder-manage --config-file ${config.cinder.config} db sync
    EOF

    systemctl start cinder-api.service cinder-scheduler.service
  '';

  placementStartScript = pkgs.writeShellScript "placement.sh" ''
    export PATH=${
      lib.makeBinPath [
        placement
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    systemctl stop placement-api.service

    source /root/os-setup/.env

    exec runuser --user placement --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password placement placement
    openstack role add --project service --user placement admin
    placement-manage --config-file ${config.placement.config} db sync
    EOF

    systemctl start placement-api.service
  '';

  novaStartScript = pkgs.writeShellScript "nova.sh" ''
    export PATH=${
      lib.makeBinPath [
        nova
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    source /root/os-setup/.env

    systemctl stop nova-conductor.service \
      nova-novncproxy.service \
      nova-scheduler.service  \
      nova-serialproxy.service \
      nova-api.service

    exec runuser --user nova --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password nova nova
    openstack role add --project service --user nova admin
    nova-manage --config-file ${config.nova.config} api_db sync
    nova-manage --config-file ${config.nova.config} cell_v2 map_cell0
    nova-manage --config-file ${config.nova.config} cell_v2 create_cell --name=cell1 --verbose
    nova-manage --config-file ${config.nova.config} db sync
    EOF

    systemctl start nova-conductor.service \
      nova-novncproxy.service \
      nova-scheduler.service  \
      nova-serialproxy.service \
      nova-api.service
  '';

  neutronStartScript = pkgs.writeShellScript "neutron.sh" ''
    export PATH=${
      lib.makeBinPath [
        neutron
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    systemctl stop neutron-dhcp-agent.service \
      neutron-metadata-agent.service \
      neutron-openvswitch-agent.service

    source /root/os-setup/.env

    exec runuser --user neutron --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password neutron neutron
    openstack role add --project service --user neutron admin
    neutron-db-manage --config-file ${config.neutron.config} --config-file ${config.neutron.ml2Config} upgrade head
    EOF

    systemctl start neutron-dhcp-agent.service \
      neutron-metadata-agent.service \
      neutron-openvswitch-agent.service

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
      install -m 0700 ${databaseCleanupScript} /root/os-setup/000-database-cleanup.sh
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
        ExecStart = "/root/os-setup/000-database-setup.sh";
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
        ExecStartPre = "+/root/os-setup/001-keystone-all-pre-start.sh";
        ExecStart = "+/root/os-setup/002-keystone-all.sh";
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
        ExecStart = "+/root/os-setup/003-glance.sh";
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
        ExecStart = "+/root/os-setup/003-cinder.sh";
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
        ExecStart = "+/root/os-setup/004-placement.sh";
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
        ExecStart = "+/root/os-setup/006-nova.sh";
      };
    };

    systemd.services.neutron = lib.mkIf (!config.openstack.production_setup) {
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
        ExecStart = "+/root/os-setup/005-neutron.sh";
      };
    };
  };
}
