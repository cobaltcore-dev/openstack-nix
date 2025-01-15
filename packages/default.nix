{ callPackage, python311Packages }:
let
  # OpenStack supports python3.11 in the release 2024.2
  python3Packages = python311Packages;

  openstackPkgs = rec {
    oslo-config = callPackage ./oslo-config.nix { inherit python3Packages oslo-i18n; };
    oslo-context = callPackage ./oslo-context.nix { inherit oslotest pre-commit python3Packages; };
    oslo-i18n = callPackage ./oslo-i18n.nix { inherit python3Packages; };
    oslotest = callPackage ./oslotest.nix { inherit oslo-config pre-commit python3Packages; };
    pre-commit = callPackage ./pre-commit.nix { inherit python3Packages; };
  };
in
{
  default = openstackPkgs.oslo-i18n;
}
// openstackPkgs
