{ callPackage, python311Packages }:
let
  # OpenStack supports python3.11 in the release 2024.2
  python3Packages = python311Packages;

  openstackPkgs = rec {
    oslo-i18n = callPackage ./oslo-i18n.nix { inherit python3Packages; };
  };
in
{
  default = openstackPkgs.oslo-i18n;
}
// openstackPkgs
