{ callPackage, python3Packages }:
let
  # In the past, the packages was not ready for the latest python interpreter.
  # Since every package is required to use the same python interpreter, we set
  # the interpreter in the toplevel, to avoid a change for every single package
  openstackPkgs = rec {
    castellan = callPackage ./castellan.nix {
      inherit
        keystoneauth1
        oslo-config
        oslo-context
        oslo-i18n
        oslo-log
        oslo-utils
        oslotest
        python-barbicanclient
        python3Packages
        ;
    };
    futurist = callPackage ./futurist.nix {
      inherit oslotest python3Packages;
    };
    gabbi = callPackage ./gabbi.nix {
      inherit jsonpath-rw-ext python3Packages;
    };
    jsonpath-rw-ext = callPackage ./jsonpath-rw-ext.nix { inherit python3Packages; };
    keystoneauth1 = callPackage ./keystoneauth1.nix {
      inherit
        oslo-config
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-cache = callPackage ./oslo-cache.nix {
      inherit
        oslo-config
        oslo-i18n
        oslo-log
        oslo-utils
        oslotest
        python-binary-memcached
        python3Packages
        ;
    };
    oslo-concurrency = callPackage ./oslo-concurrency.nix {
      inherit
        oslo-config
        oslo-i18n
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
    oslo-messaging = callPackage ./oslo-messaging.nix {
      inherit
        futurist
        oslo-config
        oslo-context
        oslo-log
        oslo-metrics
        oslo-middleware
        oslo-serialization
        oslo-service
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-metrics = callPackage ./oslo-metrics.nix {
      inherit
        oslo-config
        oslo-log
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-middleware = callPackage ./oslo-middleware.nix {
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
    oslo-service = callPackage ./oslo-service.nix {
      inherit
        oslo-concurrency
        oslo-config
        oslo-i18n
        oslo-log
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
    pycadf = callPackage ./pycadf.nix { inherit oslo-config oslo-serialization python3Packages; };
    pre-commit = callPackage ./pre-commit.nix { inherit python3Packages; };
    python-barbicanclient = callPackage ./python-barbicanclient.nix {
      inherit
        keystoneauth1
        oslo-config
        oslo-i18n
        oslo-serialization
        oslo-utils
        oslotest
        python3Packages
        sphinxcontrib-svg2pdfconverter
        ;
    };
    python-binary-memcached = callPackage ./python-binary-memcached.nix {
      inherit python3Packages uhashring;
    };
    python-keystoneclient = callPackage ./python-keystoneclient.nix {
      inherit
        keystoneauth1
        oslo-config
        oslo-i18n
        oslo-serialization
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    sphinxcontrib-svg2pdfconverter = callPackage ./sphinxcontrib-svg2pdfconverter.nix {
      inherit python3Packages;
    };
    uhashring = callPackage ./uhashring.nix { inherit python3Packages; };
  };
in
{
  default = openstackPkgs.oslo-i18n;
}
// openstackPkgs
