{ lib, config, ... }:
with lib;
{
  options.openstack.production_setup = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether the controller uses a production database setup. When enabled,
      the destructive database setup service is disabled.
    '';
  };

  options.openstack.myIp = lib.mkOption {
    # default of CI/CD setup
    default = "10.0.0.39";
    type = types.str;
    description = ''
      My own ip address.
    '';
  };
}
