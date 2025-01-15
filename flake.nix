{
  description = "OpenStack Packages and Modules for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks-nix, ... }: flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
    let
      pkgs = import nixpkgs { inherit system; };
      pre-commit-hooks-run = pre-commit-hooks-nix.lib.${system}.run;
    in
    {
      formatter = pkgs.nixpkgs-fmt;
      devShells.default = pkgs.mkShellNoCC {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
      };

      packages = {
        default = self.checks.${system}.pre-commit-check;
      };

      checks = import ./checks { inherit pkgs pre-commit-hooks-run; };
    });
}
