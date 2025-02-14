{ horizon }:
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.horizon;
  user = "nginx";
  group = "nginx";
in
{
  options.horizon = {
    enable = mkEnableOption "Enable OpenStack Dashboard" // {
      default = true;
    };

    config = mkOption {
      default = ./horizon-settings.py;
      type = types.path;
      description = ''
        The OpenStack Dashboard local_settings.py
      '';
    };
    package = mkOption {
      default = horizon;
      description = ''The Horizon Package to use'';
      type = types.package;
    };
  };

  config = {
    systemd.tmpfiles.settings = {
      "10-horizon" = {
        "/var/lib/static" = {
          D = {
            inherit user group;
            mode = "0755";
          };
        };
        "/var/lib/openstack_dashboard/" = {
          "C+" = {
            inherit user group;
            mode = "0755";
            argument = "${cfg.package}/${pkgs.python3.sitePackages}/openstack_dashboard/";
          };
          Z = {
            inherit user group;
            mode = "0766";
          };
        };
        "/var/lib/openstack_dashboard/local/.secret_key_store" = {
          z = {
            inherit user group;
            mode = "0600";
          };
        };
        "/var/lib/openstack_dashboard/local/local_settings.py" = {
          "L+" = {
            inherit user group;
            mode = "0600";
            argument = "${cfg.config}";
          };
        };
      };
    };

    services.uwsgi = {
      instance.vassals.horizon = {
        type = "normal";
        socket = "/run/uwsgi/horizon.sock";
        buffer-size = 65535;
        immediate-uid = user;
        immediate-gid = group;
        master = true;
        wsgi-file = "/var/lib/openstack_dashboard/wsgi.py";
        static-map = "/static=/var/lib/openstack_dashboard/static";
        static-map2 = "/horizon/static=/var/lib/openstack_dashboard/static";

        enable-threads = true;
        pythonPackages = _: [
          horizon
        ];
        processes = 3;
        threads = 10;
        thunder-lock = true;
        lazy-apps = true;
        chdir = "/var/lib/openstack_dashboard";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.horizon = {
        listen = [
          {
            addr = "*";
            port = 80;
          }
        ];
        extraConfig = ''
          include ${config.services.nginx.package}/conf/uwsgi_params;
        '';
        locations."/" = {
          extraConfig = "
            uwsgi_pass unix:/run/uwsgi/horizon.sock;
          ";
        };
      };
    };
  };
}
