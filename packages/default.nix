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
    doc8 = callPackage ./doc8.nix { inherit python3Packages; };
    flake8-logging-format = callPackage ./flake8-logging-format.nix { inherit python3Packages; };
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
    keystonemiddleware = callPackage ./keystonemiddleware.nix {
      inherit
        keystoneauth1
        oslo-cache
        oslo-config
        oslo-context
        oslo-i18n
        oslo-log
        oslo-messaging
        oslo-serialization
        oslo-utils
        oslotest
        pycadf
        python-keystoneclient
        python3Packages
        ;
    };
    microversion-parse = callPackage ./microversion-parse.nix {
      inherit
        gabbi
        pre-commit
        python3Packages
        ;
    };
    os-brick = callPackage ./os-brick.nix {
      inherit
        castellan
        doc8
        flake8-logging-format
        os-win
        oslo-concurrency
        oslo-config
        oslo-context
        oslo-i18n
        oslo-log
        oslo-privsep
        oslo-serialization
        oslo-service
        oslo-utils
        oslo-vmware
        oslotest
        python3Packages
        ;
    };
    os-resource-classes = callPackage ./os-resource-classes.nix {
      inherit
        oslotest
        python3Packages
        ;
    };
    os-win = callPackage ./os-win.nix {
      inherit
        oslo-concurrency
        oslo-config
        oslo-log
        oslo-utils
        oslo-i18n
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
    oslo-privsep = callPackage ./oslo-privsep.nix {
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
    oslo-vmware = callPackage ./oslo-vmware.nix {
      inherit
        oslo-concurrency
        oslo-context
        oslo-i18n
        oslo-utils
        pre-commit
        python3Packages
        suds-community
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
    suds-community = callPackage ./suds-community.nix { inherit python3Packages; };
    uhashring = callPackage ./uhashring.nix { inherit python3Packages; };
  };
in
{
  default = openstackPkgs.oslo-i18n;
}
// openstackPkgs
