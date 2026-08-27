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
    transport_url = rabbit://openstack:openstack@controller
    auth_strategy = keystone
    log_dir = /var/log/designate

    [storage:sqlalchemy]
    connection = mysql+pymysql://designate:designate@controller/designate

    [service:api]
    listen = 0.0.0.0:9001
    api_base_uri = http://controller:9001/
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
    www_authenticate_uri = http://controller:5000
    auth_url = http://controller:5000
    memcached_servers = controller:11211
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
    - name: default-knot
      description: External Knot DNS 3 pool
      attributes: {}

      ns_records:
        - hostname: ns1.example.org.
          priority: 1

      nameservers:
        - host: ${cfg.knot.address}
          port: 53

      targets:
        - type: knot3
          description: External Knot DNS 3 server
          masters:
            - host: ${config.openstack.myIp}
              port: 5354
          options:
            host: ${cfg.knot.address}
            port: 53
            ssh_bin_path: ${pkgs.openssh}/bin/ssh
            ssh_host: ${cfg.knot.sshHost}
            ssh_port: ${toString cfg.knot.sshPort}
            ssh_user: ${cfg.knot.sshUser}
            ssh_identity_file: ${cfg.knot.sshIdentityFile}
            ssh_known_hosts_file: ${cfg.knot.sshKnownHostsFile}
            knotc_bin_path: ${cfg.knot.knotcBinPath}
            confdb_path: /var/lib/knot/confdb
            control_socket: /run/knot/knot.sock
            template: designate
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
      sshHost = lib.mkOption {
        type = lib.types.str;
        default = cfg.knot.address;
        description = "SSH host used to manage Knot's dynamic zone configuration.";
      };
      sshUser = lib.mkOption {
        type = lib.types.str;
        default = "designate-knot";
        description = "Restricted account used to run knotc on the Knot server.";
      };
      sshPort = lib.mkOption {
        type = lib.types.port;
        default = 22;
        description = "SSH port of the external Knot server.";
      };
      sshIdentityFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/designate/.ssh/id_ed25519";
        description = "Runtime path to Designate's SSH private key.";
      };
      sshKnownHostsFile = lib.mkOption {
        type = lib.types.str;
        default = "/etc/ssh/ssh_known_hosts";
        description = "Known-hosts file used to authenticate the Knot server.";
      };
      knotcBinPath = lib.mkOption {
        type = lib.types.str;
        default = "${pkgs.knot-dns}/bin/knotc";
        description = "Path to knotc on the external Knot server.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.designate = {
      group = "designate";
      isSystemUser = true;
    };
    users.groups.designate = { };

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
