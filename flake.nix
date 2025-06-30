{
  description = "OpenStack Packages and Modules for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-25-05.url = "github:nixos/nixpkgs/nixos-25.05";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix tooling to build cloud-hypervisor.
    crane.url = "github:ipetkov/crane/master";
    cloud-hypervisor-src.url = "github:cyberus-technology/cloud-hypervisor/gardenlinux";
    cloud-hypervisor-src.flake = false;
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs-25-05";
    libvirt-src.url = "git+https://github.com/cyberus-technology/libvirt?ref=gardenlinux&submodules=1";
    libvirt-src.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pre-commit-hooks-run = inputs.pre-commit-hooks-nix.lib.${system}.run;
      in
      rec {
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = pkgs.mkShellNoCC {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          packages = with pkgs; [ gitlint ];
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

        packages = (import ./packages { inherit (pkgs) callPackage python3Packages; }) // {
          cloud-hypervisor =
            let
              pkgs-25-05 = import inputs.nixpkgs-25-05 { inherit (pkgs) system; };
              rust-bin = (inputs.rust-overlay.lib.mkRustBin { }) pkgs-25-05;
              artifacts = pkgs.callPackage ./chv.nix {
                inherit (inputs) cloud-hypervisor-src;
                craneLib = inputs.crane.mkLib pkgs-25-05;
                rustToolchain = rust-bin.stable.latest.default;
              };
            in
            artifacts.default;
          libvirt = pkgs.libvirt.overrideAttrs ({
            src = inputs.libvirt-src;
            patches =
              let
                patchSrc = ./patches/libvirt;
              in
              (pkgs.lib.pipe patchSrc [
                builtins.readDir
                builtins.attrNames
                # To fully-qualified path.
                (map (f: "${patchSrc}/${f}"))
              ]);
          });
        };

        checks = import ./checks { inherit pkgs pre-commit-hooks-run; };

        nixosModules = import ./modules {
          openstackPkgs = packages;
          inherit self;
        };

        tests = import ./tests/default.nix {
          inherit pkgs nixosModules;
          inherit (lib) generateRootwrapConf;
        };
      }
    )
    // {
      ci = import ./lib/gitlab-ci.nix { input = { inherit (self) packages tests; }; };
    };
}
