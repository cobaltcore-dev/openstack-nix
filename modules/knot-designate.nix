{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.knot-designate;
in
{
  options.services.knot-designate = {
    enable = lib.mkEnableOption "an external Knot DNS secondary for OpenStack Designate";

    mdnsAddress = lib.mkOption {
      type = lib.types.str;
      example = "10.0.0.39";
      description = "Address of the Designate MiniDNS server used for IXFR/AXFR.";
    };

    mdnsPort = lib.mkOption {
      type = lib.types.port;
      default = 5354;
      description = "Port of the Designate MiniDNS server.";
    };

    sshUser = lib.mkOption {
      type = lib.types.str;
      default = "designate-knot";
      description = "Account through which Designate runs knotc.";
    };

    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "SSH port on which Designate manages Knot.";
    };

    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH public keys allowed to manage Knot for Designate.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.knot = {
      enable = true;
      settings = {
        server.listen = [
          "0.0.0.0@53"
          "::@53"
        ];
        remote.designate-mdns.address = "${cfg.mdnsAddress}@${toString cfg.mdnsPort}";
        acl.designate-mdns = {
          address = [ cfg.mdnsAddress ];
          action = [ "notify" ];
        };
        template.designate = {
          master = "designate-mdns";
          acl = "designate-mdns";
          storage = "/var/lib/knot/zones";
          semantic-checks = true;
        };
      };
    };

    # Designate adds and removes zones dynamically. The configuration database
    # preserves those entries while +nopurge refreshes the declarative base
    # configuration on restart.
    systemd.services.knot = {
      preStart = ''
        ${pkgs.knot-dns}/bin/knotc \
          --confdb=/var/lib/knot/confdb \
          conf-import /etc/knot/knot.conf +nopurge
      '';
      serviceConfig = {
        ExecStart = lib.mkForce "${pkgs.knot-dns}/bin/knotd --confdb=/var/lib/knot/confdb --socket=/run/knot/knot.sock";
        UMask = lib.mkForce "0007";
      };
    };

    users.groups.${cfg.sshUser} = { };
    users.users.${cfg.sshUser} = {
      isSystemUser = true;
      group = cfg.sshUser;
      extraGroups = [ "knot" ];
      home = "/var/lib/${cfg.sshUser}";
      createHome = true;
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    };

    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
    };

    networking.firewall.allowedTCPPorts = [
      53
      cfg.sshPort
    ];
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}
