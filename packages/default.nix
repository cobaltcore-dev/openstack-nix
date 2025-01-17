{ callPackage, python311Packages }:
let
  # OpenStack supports python3.11 in the release 2024.2
  python3Packages = python311Packages;

  openstackPkgs = rec {
    keystoneauth1 = callPackage ./keystoneauth1.nix {
      inherit
        oslo-config
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-config = callPackage ./oslo-config.nix { inherit python3Packages oslo-i18n; };
    oslo-context = callPackage ./oslo-context.nix { inherit oslotest pre-commit python3Packages; };
    oslo-i18n = callPackage ./oslo-i18n.nix { inherit python3Packages; };
    oslo-log = callPackage ./oslo-log.nix {
      inherit
        oslo-config
        oslo-context
        oslo-i18n
        oslo-serialization
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-serialization = callPackage ./oslo-serialization.nix {
      inherit
        oslo-i18n
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-utils = callPackage ./oslo-utils.nix {
      inherit
        oslo-config
        oslo-i18n
        oslotest
        python3Packages
        ;
    };
    oslotest = callPackage ./oslotest.nix { inherit oslo-config pre-commit python3Packages; };
    pre-commit = callPackage ./pre-commit.nix { inherit python3Packages; };
  };
in
{
  default = openstackPkgs.oslo-i18n;
}
// openstackPkgs
