{
  description = "OpenStack Packages and Modules for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks-nix,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pre-commit-hooks-run = pre-commit-hooks-nix.lib.${system}.run;
      in
      rec {
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = pkgs.mkShellNoCC {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };

        lib = {
          generateRootwrapConf =
            {
              package,
              filterPath,
              execDirs,
            }:
            pkgs.callPackage ./lib/rootwrap-conf.nix {
              inherit package filterPath;
              utils_env = execDirs;
            };
        };

        packages = import ./packages { inherit (pkgs) callPackage python3Packages; };

        checks = import ./checks { inherit pkgs pre-commit-hooks-run; };

        nixosModules = import ./modules { openstackPkgs = packages; };

        tests = import ./tests/default.nix { inherit pkgs nixosModules; };
      }
    )
    // {
      ci = import ./lib/gitlab-ci.nix { input = { inherit (self) packages tests; }; };
    };
}
