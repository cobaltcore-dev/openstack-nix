{ designate }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.designate;

  designateConf = pkgs.writeText "designate.conf" ''
    [DEFAULT]
    transport_url = rabbit://openstack:openstack@${config.openstack.controllerHostname}
    auth_strategy = keystone
    log_dir = /var/log/designate
    root_helper = "/run/wrappers/bin/sudo ${designate}/bin/designate-rootwrap ${rootwrapConf}"

    [storage:sqlalchemy]
    connection = mysql+pymysql://designate:designate@${config.openstack.controllerHostname}/designate

    [service:api]
    listen = 0.0.0.0:9001
    api_base_uri = http://${config.openstack.controllerHostname}:9001/
    api_paste_config = ${designate}/etc/designate/api-paste.ini
    auth_strategy = keystone
    enable_api_v2 = true
    enable_api_admin = true
    enable_host_header = true
    enabled_extensions_admin = quotas,reports

    [service:mdns]
    listen = 0.0.0.0:5354

    [service:worker]
    threads = 20

    [keystone_authtoken]
    www_authenticate_uri = http://${config.openstack.controllerHostname}:5000
    auth_url = http://${config.openstack.controllerHostname}:5000
    memcached_servers = ${config.openstack.controllerHostname}:11211
    auth_type = password
    project_domain_name = Default
    user_domain_name = Default
    project_name = service
    username = designate
    password = designate

    [oslo_concurrency]
    lock_path = /var/lib/designate/tmp
  '';

  designatePools = pkgs.writeText "pools.yaml" ''
    - name: default
      description: Designate bind backend pool
      attributes: {}

      ns_records:
        - hostname: osdns.openstack.test.
          priority: 2
        - hostname: controller.openstack.test.
          priority: 1

      # List out the nameservers for this pool. These are the actual BIND servers.
      # We use these to verify changes have propagated to all nameservers.
      nameservers:
        # controller bind
        - host: ${config.openstack.controllerIP}
          port: 53
        # dedicated dns server knot (replace it later)
        - host: ${cfg.knot.address}
          port: 53

      # List out the targets for this pool. For BIND, most often, there will be one
      # entry for each BIND server.
      targets:
        - type: bind9
          description: local bind server on controller

          # List out the designate-mdns servers from which BIND servers should
          # request zone transfers (AXFRs) from.
          masters:
              # IP address of controller
            - host: ${config.openstack.controllerIP}
              port: 5354

          # BIND Configuration options
          # in our use case localhost == controller
          options:
            host: 127.0.0.1
            port: 53
            rndc_host: 127.0.0.1
            rndc_port: 953
            rndc_key_file: /etc/bind/rndc.key
            # set relative path so rootwrap works
            rndc_bin_path: rndc

      also_notifies:
        - host: ${cfg.knot.address}
          port: 53
  '';

  service = command: {
    after = [
      "rabbitmq.service"
      "mysql.service"
      "network.target"
    ]
    ++ lib.optional (!config.openstack.production_setup) "designate.service";
    requires = lib.optional (!config.openstack.production_setup) "designate.service";
    wantedBy = [ "multi-user.target" ];
    path = [ designate ];
    restartTriggers = [ cfg.config ];
    serviceConfig = {
      User = "designate";
      Group = "designate";
      ExecStart = "${designate}/bin/${command} --config-file=${cfg.config}";
      Restart = "on-failure";
    };
  };

  designate_env = pkgs.python3.buildEnv.override {
    extraLibs = [ designate ];
  };
  utils_env = pkgs.buildEnv {
    name = "utils";
    paths = with pkgs; [
      designate_env
      bind
    ];
  };

  rootwrapConf = pkgs.callPackage ../../lib/rootwrap-conf.nix {
    package = designate_env;
    filterPath = "/etc/designate/rootwrap.d";
    inherit utils_env;
  };

in
{
  options.designate = {
    enable = lib.mkEnableOption "OpenStack Designate with a Knot DNS backend" // {
      default = false;
    };

    config = lib.mkOption {
      type = lib.types.path;
      default = designateConf;
      description = "Designate configuration file.";
    };

    pools = lib.mkOption {
      type = lib.types.path;
      default = designatePools;
      description = "Designate pools.yaml containing the Knot target.";
    };

    knot = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "192.168.200.23";
        description = "IP address of the external Knot DNS server.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.designate = {
      group = "designate";
      isSystemUser = true;
    };
    users.groups.designate = { };

    security.sudo.enable = true;
    security.sudo.extraConfig = ''
      designate ALL = (root) NOPASSWD: ${designate}/bin/designate-rootwrap ${rootwrapConf} *
    '';

    systemd.tmpfiles.settings."10-designate" = {
      "/etc/designate/designate.conf"."L+".argument = "${cfg.config}";
      "/etc/designate/pools.yaml"."L+".argument = "${cfg.pools}";
      "/var/lib/designate".d = {
        user = "designate";
        group = "designate";
        mode = "0755";
      };
      "/var/lib/designate/.ssh".d = {
        user = "designate";
        group = "designate";
        mode = "0755";
      };
      "/var/lib/designate/tmp".D = {
        user = "designate";
        group = "designate";
        mode = "0755";
      };
      "/var/log/designate".d = {
        user = "designate";
        group = "designate";
        mode = "0755";
      };
    };

    systemd.services.designate-api = service "designate-api";
    systemd.services.designate-central = service "designate-central";
    systemd.services.designate-mdns = service "designate-mdns";
    systemd.services.designate-producer = service "designate-producer";
    systemd.services.designate-worker = lib.recursiveUpdate (service "designate-worker") {
      path = [
        designate
        pkgs.openssh
        pkgs.sudo
      ];
    };

    networking.firewall.allowedTCPPorts = [ 5354 ];
    networking.firewall.allowedUDPPorts = [ 5354 ];

    systemd.services.designate-pool-update = {
      description = "Update the OpenStack Designate pools";
      after = [ "designate-central.service" ];
      requires = [ "designate-central.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ designate ];
      restartTriggers = [ cfg.pools ];
      serviceConfig = {
        Type = "oneshot";
        User = "designate";
        Group = "designate";
        ExecStart = "${designate}/bin/designate-manage --config-file=${cfg.config} pool update --file=${cfg.pools}";
      };
    };
  };
}
