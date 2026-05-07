{
  description = "OpenStack Packages and Modules for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nova-src = {
      url = "git+file:/home/skober/repos/nova";
      # url = "git+ssh://git@gitlab.cyberus-technology.de/cyberus/cloud/openstack-nova.git";
      # url = "git+https://github.com/sapcc/nova?ref=stable/2023.2-m3";
      flake = false;
    };

    libvirt = {
      # A local path can be used for developing or testing local changes. Make
      # sure the submodules in a local libvirt checkout are populated.
      # url = "git+file:<path/to/libvirt>?submodules=1";
      url = "git+https://github.com/cyberus-technology/libvirt?ref=gardenlinux&submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks-nix,
      nova-src,
      libvirt,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        pre-commit-hooks-run = pre-commit-hooks-nix.lib.${system}.run;
        # The PBR setup does not work on the plain source code because no
        # package version can be determined.
        # We add a PKG-INFO file with the missing information to make it work.
        # We use the version info of the original Nova package from
        # openstack-nix.
        fixedNovaSrc = pkgs.runCommand "add-package-info" { } ''
          mkdir -p $out

          cp -r ${nova-src}/. $out

          cat >$out/PKG-INFO <<EOL
          Metadata-Version: 2.1
          Name: nova
          Version: 30.0.0
          EOL
        '';
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

        packages = import ./packages { inherit (pkgs) callPackage python3Packages; };
        novaPkg = packages.nova.overrideAttrs (_: {
          src = fixedNovaSrc;
          doInstallCheck = false;
        });

        packages2 = packages // {
          nova = novaPkg;
        };

        checks = import ./checks { inherit pkgs pre-commit-hooks-run; };

        nixosModules = import ./modules { openstackPkgs = packages; };
        inherit libvirt;

        tests = import ./tests/default.nix {
          libvirt = libvirt.packages.x86_64-linux.libvirt;
          inherit pkgs nixosModules novaPkg;
          inherit (lib) generateRootwrapConf;
        };
      }
    )
    // {
      ci = import ./lib/gitlab-ci.nix { input = { inherit (self) packages tests; }; };
    };
}
