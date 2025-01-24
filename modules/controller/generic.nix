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
}
