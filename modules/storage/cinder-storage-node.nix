{
  cinder,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.cinder-storage-node;

  cinder_env = pkgs.python3.buildEnv.override {
    extraLibs = [
      cfg.cinderPackage
      pkgs.qemu
    ];
  };

  utils_env = pkgs.buildEnv {
    name = "utils";
    paths = [
      cinder_env
      pkgs.qemu
      pkgs.tgt
    ];
  };

  rootwrapConf = pkgs.callPackage ../../lib/rootwrap-conf.nix {
    package = cinder_env;
    filterPath = "/etc/cinder/rootwrap.d";
    inherit utils_env;
  };

  cinderConfLvm = pkgs.writeText "cinder.conf" ''
    [DEFAULT]
    transport_url = rabbit://openstack:openstack@controller
    auth_strategy = keystone
    my_ip = 10.0.0.20
    enabled_backends = lvm
    volumes_dir = /var/lib/cinder/volumes
    state_path = /var/lib/cinder
    rootwrap_config = ${rootwrapConf}
    glance_api_servers = http://controller:9292
    verify_glance_signatures = disabled
    log_dir = /var/log/cinder
    iscsi_ip_address = $my_ip
    iscsi_port = 3260
    iscsi_target_prefix = iqn.2010-10.org.openstack:

    [database]
    connection = mysql+pymysql://cinder:cinder@controller/cinder

    [keystone_authtoken]
    www_authenticate_uri = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = default
    user_domain_name = default
    project_name = service
    username = cinder
    password = cinder
    service_token_roles_required = true
    service_token_roles = admin

    [oslo_concurrency]
    lock_path = /var/lib/cinder/tmp

    [lvm]
    volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
    volume_group = cinder-volumes
    volume_backend_name = lvm
    lvm_type = default
    target_protocol = iscsi
    target_helper = tgtadm
    iscsi_ip_address = $my_ip
    iscsi_port = 3260
    iscsi_target_prefix = iqn.2010-10.org.openstack:
  '';

  cinderConfNfs = pkgs.writeText "cinder.conf" ''
    [DEFAULT]
    transport_url = rabbit://openstack:openstack@controller
    auth_strategy = keystone
    my_ip = 10.0.0.20
    enabled_backends = nfs
    volumes_dir = /var/lib/cinder/volumes
    state_path = /var/lib/cinder
    rootwrap_config = ${rootwrapConf}
    glance_api_servers = http://controller:9292
    verify_glance_signatures = disabled
    log_dir = /var/log/cinder

    [database]
    connection = mysql+pymysql://cinder:cinder@controller/cinder

    [keystone_authtoken]
    www_authenticate_uri = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
    auth_type = password
    project_domain_name = default
    user_domain_name = default
    project_name = service
    username = cinder
    password = cinder
    service_token_roles_required = true
    service_token_roles = admin

    [oslo_concurrency]
    lock_path = /var/lib/cinder/tmp

    [nfs]
    volume_driver = cinder.volume.drivers.nfs.NfsDriver
    nfs_shares_config = /etc/cinder/nfs_shares
    nfs_mount_options = vers=3
  '';

  cinderTgtConf = pkgs.writeText "cinder.conf" ''
    include /var/lib/cinder/volumes/*
  '';

  cinderDefaultNFSexports = pkgs.writeText "exports" ''
    /exports 10.0.0.0/24(rw,no_root_squash,insecure)
  '';

  cinderVolumeSetupScript = pkgs.writeShellScript "cinder-volume-setup.sh" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.util-linux
      ]
    }:$PATH

    if [ -e /exports/.cinder-volume-setup-done-dont-delete-me ]; then
      echo "cinder volume setup already done. Check content of this script."
    fi

    mkdir /exports
    mkfs.ext4 -F -m 0 -L cinder /dev/vdb
    mount /dev/vdb /exports
    exportfs -rv
    rm -rf /exports/lost+found
    chown cinder /exports
    chgrp cinder /exports

    systemctl restart cinder-volume.service
    touch /exports/.cinder-volume-setup-done-dont-delete-me
  '';

in
{
  imports = [
    ../generic/global-options.nix
    ../generic/controller-host-entry.nix
  ];

  options.openstack = {
    storageIP = mkOption {
      type = types.str;
      default = "10.0.0.20";
      description = ''
        IP address of the storage node.
      '';
    };
  };

  options.cinder-storage-node = {
    enable = mkEnableOption "Enable OpenStack Cinder storage node." // {
      default = true;
    };
    config = mkOption {
      default = if (cfg.backend == "lvm") then cinderConfLvm else cinderConfNfs;
      description = ''
        The Cinder config.
      '';
    };
    cinderPackage = mkOption {
      default = cinder;
      type = types.package;
      description = ''
        The OpenStack Cinder package to use.
      '';
    };
    backend = mkOption {
      default = "nfs";
      type =
        with types;
        enum [
          "lvm"
          "nfs"
        ];
      description = ''
        Type of Cinder Storage backend.
        Possible options: [ lvm | nfs ]
      '';
    };
    exports = mkOption {
      default = cinderDefaultNFSexports;
      description = ''
        The nfs-server /etc/exports file.
      '';
    };
  };

  config = {

    system.activationScripts.openstack-setup-scripts.text = ''
      install -d -m 0700 /root/os-setup
      install -m 0700 ${cinderVolumeSetupScript} /root/os-setup/000-cinder-volume-setup.sh
    '';

    users.extraUsers.cinder = {
      group = "cinder";
      isSystemUser = true;
    };
    users.groups.cinder = {
      name = "cinder";
      members = [ "cinder" ];
    };

    security.sudo.enable = true;
    security.sudo.extraConfig = ''
      cinder ALL = (root) NOPASSWD: ${cinder_env}/bin/cinder-rootwrap ${rootwrapConf} *
    '';

    systemd.tmpfiles.settings = {
      "20-cinder" = {
        "/var/lib/cinder/" = {
          d = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/var/lib/cinder/volumes" = {
          d = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/var/log/cinder/" = {
          d = {
            user = "cinder";
            group = "cinder";
            mode = "0755";
          };
        };
        "/etc/cinder/cinder.conf" = {
          "L+" = {
            argument = "${cfg.config}";
          };
        };
      };
      "20-cinder-backend" =
        if (cfg.backend == "lvm") then
          # LVM configuration files
          {
            "/etc/tgt/conf.d/cinder.conf" = {
              "L+" = {
                argument = "${cinderTgtConf}";
              };
            };
            "/etc/tgt/targets.conf" = {
              "L+" = {
                argument = "${pkgs.tgt}/etc/tgt/targets.conf";
              };
            };
          }
        else
          # NFS configuration files
          {
            "/etc/cinder/nfs_shares" = {
              "f+" = {
                user = "cinder";
                group = "cinder";
                mode = "0644";
                argument = ''
                  ${config.openstack.storageIP}:/exports
                '';
              };
            };
          };
    };

    # start iSCSI target daemon
    # we expose LVM block storage as iSCSI to compute hosts
    systemd.services.tgtd = {
      enable = if (cfg.backend == "lvm" && cfg.enable) then true else false;
      description = "iSCSI target framework daemon";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "cinder-volume-group-setup.service"
      ];
      path = [
        pkgs.coreutils
        pkgs.tgt
      ];
      environment.TGTD_CONFIG = "/etc/tgt/targets.conf";
      serviceConfig = {
        ExecStart = "${pkgs.tgt}/bin/tgtd -f";
        ExecStartPost = [
          "${pkgs.coreutils}/bin/sleep 5"
          "${pkgs.tgt}/bin/tgtadm --op update --mode sys --name State -v offline"
          "${pkgs.tgt}/bin/tgtadm --op update --mode sys --name State -v ready"
          "${pkgs.tgt}/bin/tgt-admin -e -c $TGTD_CONFIG"
        ];

        ExecReload = "${pkgs.tgt}/bin/tgt-admin --update ALL -f -c $TGTD_CONFIG";

        ExecStop = [
          "${pkgs.tgt}/bin/tgtadm --op update --mode sys --name State -v offline"
          "${pkgs.tgt}/bin/tgt-admin --offline ALL"
          "${pkgs.tgt}/bin/tgt-admin --update ALL -c /dev/null -f"
          "${pkgs.tgt}/bin/tgtadm --op delete --mode system"
        ];
      };
    };

    services.nfs.server.enable = if (cfg.backend == "lvm") then false else true;
    services.nfs.server.exports = builtins.readFile cfg.exports;

    # run this service only in CI/CD setups
    systemd.services.cinder-volume-group-setup = lib.mkIf (!config.openstack.production_setup) {
      description = "OpenStack Cinder volume group setup";
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        lvm2
        util-linux
        e2fsprogs
        nfs-utils
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          if (cfg.backend == "lvm") then
            pkgs.writeShellScript "cinder-volume-group.sh" ''
              set -euxo pipefail

              # create a new LVM volume group on second disk
              pvcreate /dev/vdb
              vgcreate cinder-volumes /dev/vdb
            ''
          else
            pkgs.writeShellScript "cinder-volume-group.sh" ''
              set -euxo pipefail

              # create a filesystem and mount and export it
              mkdir /exports
              mkfs.ext4 -F -m 0 /dev/vdb
              mount /dev/vdb /exports
              exportfs -rv
            '';
      };
      enable = cfg.enable;
    };

    # It seems regardless of what we do, the cinder-volume service does not
    # find the qemu-img command it requires for non-raw images. As a
    # workaround, add it as a systemPackage.
    # Update: still does not work -.-

    environment.systemPackages =
      if (cfg.backend == "lvm") then
        with pkgs;
        [
          qemu
          tgt
        ]
      else
        with pkgs;
        [
          qemu
          nfs-utils
          e2fsprogs
        ];

    systemd.services.cinder-volume = {
      description = "OpenStack Cinder Volume";
      after = [
        "cinder-volume-group-setup.service"
      ];
      path =
        if (cfg.backend == "lvm") then
          with pkgs;
          [
            cinder_env
            lvm2
            tgt
            qemu-utils
            # sudo must be in the path and only sudo in /run/wrappers has the
            # correct owner and rights
            "/run/wrappers"
          ]
        else
          with pkgs;
          [
            cinder_env
            lvm2
            qemu-utils
            # sudo must be in the path and only sudo in /run/wrappers has the
            # correct owner and rights
            "/run/wrappers"
          ];

      environment.PYTHONPATH = "${cinder_env}/${pkgs.python3.sitePackages}";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "cinder";
        Group = "cinder";
        ExecStart = pkgs.writeShellScript "cinder-volume.sh" ''
          .cinder-volume-wrapped --config-file ${cfg.config}
        '';
        # The volume service requires some cinder setup to be done already and
        # manifested in the DB. As the storage node might run on a different
        # node and we cannot simply wait for some other service to complete, we
        # add a retry mechanism with some sensible delay.
        Restart = "on-failure";
        RestartSec = 20;
      };
      enable = cfg.enable;
    };
  };
}
