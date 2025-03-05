{
  lib,
  pkgs,
  ...
}:
{
  services.mysql.enable = true;
  services.mysql.package = lib.mkDefault pkgs.mariadb;

  services.rabbitmq = {
    enable = true;
    listenAddress = "0.0.0.0";
    configItems = {
      "default_user" = "openstack";
      "default_pass" = "openstack";
      "default_permissions.configure" = ".*";
      "default_permissions.read" = ".*";
      "default_permissions.write" = ".*";
    };
  };

  services.memcached.enable = true;

  systemd.tmpfiles.settings = {
    "10-uwsgi" = {
      "/run/uwsgi" = {
        D = {
          user = "nginx";
          group = "nginx";
          mode = "0755";
        };
      };
    };
  };

  services.uwsgi = {
    enable = true;
    plugins = [ "python3" ];
    user = "nginx";
    group = "nginx";
    capabilities = [
      "CAP_SETGID"
      "CAP_SETUID"
    ];
    instance.type = "emperor";
  };
}
