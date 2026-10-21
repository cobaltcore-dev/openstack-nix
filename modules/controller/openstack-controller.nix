{
  nova,
  neutron,
  keystone,
  glance,
  placement,
  horizon,
  cinder,
  python-openstackclient,
  designate,
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
    OS_AUTH_URL = "http://${config.openstack.controllerHostname}:5000/v3";
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
    mariadb -N -e "drop database designate;" || true
  '';

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
    set -euxo pipefail

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

    # Designate
    mariadb -N -e "CREATE DATABASE IF NOT EXISTS designate CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mariadb -N -e "CREATE USER IF NOT EXISTS 'designate'@'%' IDENTIFIED BY 'designate';"
    mariadb -N -e "ALTER USER 'designate'@'%' IDENTIFIED BY 'designate';"
    mariadb -N -e "GRANT ALL PRIVILEGES ON designate.* TO 'designate'@'%';"

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

    runuser --user keystone --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
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

    mkdir -p /var/lib/glance
    mkdir -p /var/lib/glance/images
    chown -R glance /var/lib/glance
    chgrp -R glance /var/lib/glance

    mkdir -p /var/log/glance
    chown glance /var/log/glance
    chgrp glance /var/log/glance

    runuser --user glance --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
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

    runuser --user cinder --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
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

    runuser --user placement --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
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

    runuser --user nova --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
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

    runuser --user neutron --preserve-environment -- ${pkgs.runtimeShell} <<'EOF'
    set -euxo pipefail
    openstack user create --domain default --password neutron neutron
    openstack role add --project service --user neutron admin
    neutron-db-manage --config-file ${config.neutron.config} --config-file ${config.neutron.ml2Config} upgrade head
    EOF
  '';

  designateStartScript = pkgs.writeShellScript "designate.sh" ''
    export PATH=${
      lib.makeBinPath [
        designate
        pkgs.openstackclient
        pkgs.util-linux
      ]
    }:$PATH

    set -euxo pipefail

    runuser --user designate -- \
      ${designate}/bin/designate-manage --config-file ${config.designate.config} database sync

    openstack user show designate >/dev/null 2>&1 || \
      openstack user create --domain default --password designate designate
    openstack role add --project service --user designate admin
  '';

  checkControllerScript = pkgs.writeShellScript "check-controller.sh" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.openstackclient
      ]
    }:$PATH

    systemctl status neutron-server.service
    systemctl status glance-api.service
    systemctl status uwsgi.service
    systemctl status cinder-scheduler.service
    systemctl status nova-api.service
    systemctl status nova-scheduler.service
    systemctl status nova-conductor.service
    systemctl status nova-novncproxy.service
    systemctl status nova-serialproxy.service
  '';

in
{
  imports = [
    ../generic/global-options.nix
    ./generic.nix
    ../generic/controller-host-entry.nix
    (import ./keystone.nix { inherit keystone; })
    (import ./glance.nix { inherit glance; })
    (import ./placement.nix { inherit placement; })
    (import ./nova.nix { inherit nova; })
    (import ./neutron.nix { inherit neutron; })
    (import ./horizon.nix { inherit horizon; })
    (import ./cinder.nix { inherit cinder; }) # only cinder management component
    (import ./designate.nix { inherit designate; })
  ];

  config = {

    environment.systemPackages = [
      (setupCommand "openstack-database-cleanup-000" databaseCleanupScript)
      (setupCommand "openstack-database-setup-000" databaseSetupScript)
      (setupCommand "openstack-keystone-pre-setup-001" keystonePreStartScript)
      (setupCommand "openstack-keystone-setup-002" keystoneStartScript)
      (setupCommand "openstack-glance-setup-003" glanceStartScript)
      (setupCommand "openstack-cinder-setup-004" cinderStartScript)
      (setupCommand "openstack-placement-setup-005" placementStartScript)
      (setupCommand "openstack-neutron-setup-006" neutronStartScript)
      (setupCommand "openstack-nova-setup-007" novaStartScript)
      (setupCommand "openstack-designate-setup-008" designateStartScript)
      (setupCommand "openstack-check-controller-100" checkControllerScript)
      python-openstackclient
      cinder
      designate
      glance
      keystone
      neutron
      nova
      placement
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
        ExecStartPre = "${databaseCleanupScript}";
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
        User = "root";
        Group = "root";
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
        User = "root";
        Group = "root";
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
        User = "root";
        Group = "root";
        ExecStart = "+${cinderStartScript}";
        RuntimeDirectory = "cinder-setup";
        ExecStartPost = "${pkgs.coreutils}/bin/touch /run/cinder-setup/ready";
      };
    };

    # Placement service can be tested by executing
    # curl http://${config.openstack.controllerHostname}:8778
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
        User = "root";
        Group = "root";
        ExecStart = "+${placementStartScript}";
        RuntimeDirectory = "placement-setup";
        ExecStartPost = "${pkgs.coreutils}/bin/touch /run/placement-setup/ready";
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
        User = "root";
        Group = "root";
        ExecStart = "+${novaStartScript}";
      };
    };

    systemd.services.neutron = lib.mkIf (!config.openstack.manual_setup) {
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
        User = "root";
        Group = "root";
        ExecStart = "+${neutronStartScript}";
      };
    };

    systemd.services.designate = lib.mkIf (config.designate.enable && !config.openstack.manual_setup) {
      description = "OpenStack Designate setup";
      after = [ "keystone-all.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = adminEnv;
      path = [
        pkgs.gnugrep
        pkgs.openstackclient
        pkgs.util-linux
        designate
      ];
      restartIfChanged = false;
      serviceConfig = {
        RemainAfterExit = true;
        Type = "oneshot";
        User = "root";
        Group = "root";
        ExecStart = "+${designateStartScript}";
      };
    };
  };
}
