{
  # from flake inputs
  craneLib,
  # from nixpkgs
  openssl,
  pkg-config,
  # other
  cloud-hypervisor-src,
  rustToolchain,
}:

let
  craneLib' = craneLib.overrideToolchain rustToolchain;

  commonArgs = {
    src = craneLib'.cleanCargoSource cloud-hypervisor-src;
    nativeBuildInputs = [
      pkg-config
    ];
    buildInputs = [
      openssl
    ];
    # Fix build. Reference:
    # - https://github.com/sfackler/rust-openssl/issues/1430
    # - https://docs.rs/openssl/latest/openssl/
    OPENSSL_NO_VENDOR = true;
  };

  # Downloaded and compiled dependencies.
  cargoArtifacts = craneLib'.buildDepsOnly (
    commonArgs
    // {
      pname = "cloud-hypervisor-deps";
    }
  );

  cargoPackageKvm = craneLib'.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts;
      pname = "cloud-hypervisor";
      # Don't execute tests here. We want this in a dedicated step.
      doCheck = false;
      cargoExtraArgs = "--features kvm";
    }
  );
in
{
  default = cargoPackageKvm;
  chvKvm = cargoPackageKvm;
}
