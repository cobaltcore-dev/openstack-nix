{ callPackage, python3Packages }:
let
  # In the past, the packages was not ready for the latest python interpreter.
  # Since every package is required to use the same python interpreter, we set
  # the interpreter in the toplevel, to avoid a change for every single package
  openstackPkgs = rec {
    automaton = callPackage ./automaton.nix { inherit python3Packages; };
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
    cursive = callPackage ./cursive.nix {
      inherit
        castellan
        oslo-i18n
        oslo-log
        oslo-serialization
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    django-debreach = callPackage ./django-debreach.nix { inherit python3Packages; };
    doc8 = callPackage ./doc8.nix { inherit python3Packages; };
    enmerkar = callPackage ./enmerkar.nix { inherit python3Packages; };
    etcd3gw = callPackage ./etcd3gw.nix { inherit futurist python3Packages; };
    flake8-logging-format = callPackage ./flake8-logging-format.nix { inherit python3Packages; };
    futurist = callPackage ./futurist.nix {
      inherit oslotest python3Packages;
    };
    gabbi = callPackage ./gabbi.nix {
      inherit jsonpath-rw-ext python3Packages;
    };
    glance-store = callPackage ./glance-store.nix {
      inherit
        castellan
        cursive
        keystoneauth1
        keystonemiddleware
        os-brick
        os-win
        oslo-db
        oslo-i18n
        oslo-limit
        oslo-log
        oslo-messaging
        oslo-middleware
        oslo-reports
        oslo-upgradecheck
        oslo-vmware
        oslotest
        osprofiler
        python-cinderclient
        taskflow
        python3Packages
        ;
    };
    glance = callPackage ./glance.nix {
      inherit
        castellan
        cursive
        glance-store
        keystoneauth1
        keystonemiddleware
        os-brick
        os-win
        oslo-db
        oslo-i18n
        oslo-limit
        oslo-log
        oslo-messaging
        oslo-middleware
        oslo-policy
        oslo-reports
        oslo-upgradecheck
        osprofiler
        python-cinderclient
        python3Packages
        taskflow
        wsme
        ;
    };
    jsonpath-rw-ext = callPackage ./jsonpath-rw-ext.nix { inherit python3Packages; };
    keystone = callPackage ./keystone.nix {
      inherit
        keystonemiddleware
        oslo-cache
        oslo-db
        oslo-log
        oslo-messaging
        oslo-middleware
        oslo-policy
        oslo-serialization
        oslo-upgradecheck
        oslotest
        osprofiler
        python-keystoneclient
        python3Packages
        ;
    };
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
    openstacksdk = python3Packages.openstacksdk.override {
      inherit keystoneauth1;
    };
    neutron-lib = callPackage ./neutron-lib.nix {
      inherit
        keystoneauth1
        os-ken
        os-traits
        oslo-concurrency
        oslo-config
        oslo-context
        oslo-db
        oslo-i18n
        oslo-log
        oslo-messaging
        oslo-policy
        oslo-serialization
        oslo-service
        oslo-utils
        oslo-versionedobjects
        oslotest
        osprofiler
        python3Packages
        ;
    };
    neutron = callPackage ./neutron.nix {
      inherit
        doc8
        futurist
        keystoneauth1
        keystonemiddleware
        neutron-lib
        openstacksdk
        os-ken
        os-resource-classes
        os-vif
        oslo-cache
        oslo-concurrency
        oslo-config
        oslo-context
        oslo-db
        oslo-i18n
        oslo-log
        oslo-messaging
        oslo-middleware
        oslo-policy
        oslo-privsep
        oslo-reports
        oslo-rootwrap
        oslo-serialization
        oslo-service
        oslo-upgradecheck
        oslo-utils
        oslo-versionedobjects
        oslotest
        osprofiler
        ovs
        ovsdbapp
        python-designateclient
        python-neutronclient
        python-novaclient
        python3Packages
        tooz
        ;
    };
    nova = callPackage ./nova.nix {
      inherit
        castellan
        cursive
        futurist
        gabbi
        keystoneauth1
        keystonemiddleware
        microversion-parse
        openstacksdk
        os-brick
        os-resource-classes
        os-traits
        os-vif
        oslo-cache
        oslo-concurrency
        oslo-config
        oslo-context
        oslo-db
        oslo-i18n
        oslo-limit
        oslo-log
        oslo-messaging
        oslo-middleware
        oslo-policy
        oslo-privsep
        oslo-reports
        oslo-rootwrap
        oslo-serialization
        oslo-service
        oslo-upgradecheck
        oslo-utils
        oslo-versionedobjects
        oslotest
        osprofiler
        python-barbicanclient
        python-cinderclient
        python-glanceclient
        python-neutronclient
        python3Packages
        tooz
        ;
    };
    openstack-placement = callPackage ./openstack-placement.nix {
      inherit
        keystonemiddleware
        microversion-parse
        os-resource-classes
        os-traits
        oslo-concurrency
        oslo-config
        oslo-context
        oslo-db
        oslo-log
        oslo-middleware
        oslo-serialization
        oslo-upgradecheck
        oslo-utils
        oslotest
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
    os-client-config = callPackage ./os-client-config.nix {
      inherit
        openstacksdk
        oslotest
        python-glanceclient
        python3Packages
        ;
    };
    os-ken = callPackage ./os-ken.nix {
      inherit
        oslo-config
        oslotest
        ovs
        python3Packages
        ;
    };
    os-resource-classes = callPackage ./os-resource-classes.nix {
      inherit
        oslotest
        python3Packages
        ;
    };
    os-traits = callPackage ./os-traits.nix {
      inherit
        oslotest
        python3Packages
        ;
    };
    os-vif = callPackage ./os-vif.nix {
      inherit
        oslo-concurrency
        oslo-config
        oslo-i18n
        oslo-log
        oslo-privsep
        oslo-serialization
        oslo-utils
        oslo-versionedobjects
        oslotest
        ovs
        ovsdbapp
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
    osc-lib = python3Packages.osc-lib.override {
      inherit
        openstacksdk
        oslo-i18n
        oslo-utils
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
    oslo-db = callPackage ./oslo-db.nix {
      inherit
        oslo-config
        oslo-context
        oslo-i18n
        oslo-utils
        oslotest
        pre-commit
        python3Packages
        ;
    };
    oslo-i18n = callPackage ./oslo-i18n.nix { inherit python3Packages; };
    oslo-limit = callPackage ./oslo-limit.nix {
      inherit
        keystoneauth1
        openstacksdk
        oslo-config
        oslo-i18n
        oslo-log
        oslotest
        python3Packages
        ;
    };
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
    oslo-policy = callPackage ./oslo-policy.nix {
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
    oslo-reports = callPackage ./oslo-reports.nix {
      inherit
        oslo-config
        oslo-i18n
        oslo-serialization
        oslo-utils
        oslotest
        python3Packages
        ;
    };
    oslo-rootwrap = callPackage ./oslo-rootwrap.nix {
      inherit
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
    oslo-upgradecheck = callPackage ./oslo-upgradecheck.nix {
      inherit
        oslo-config
        oslo-i18n
        oslo-policy
        oslo-serialization
        oslo-utils
        oslotest
        pre-commit
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
    oslo-versionedobjects = callPackage ./oslo-versionedobjects.nix {
      inherit
        oslo-concurrency
        oslo-config
        oslo-context
        oslo-i18n
        oslo-log
        oslo-messaging
        oslo-serialization
        oslo-utils
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
    osprofiler = callPackage ./osprofiler.nix {
      inherit
        oslo-concurrency
        oslo-config
        oslo-serialization
        oslo-utils
        pre-commit
        python3Packages
        ;
    };
    ovs = callPackage ./ovs.nix { inherit python3Packages; };
    ovsdbapp = callPackage ./ovsdbapp.nix { inherit oslotest ovs python3Packages; };
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
    python-designateclient = callPackage ./python-designateclient.nix {
      inherit
        keystoneauth1
        osc-lib
        oslo-config
        oslo-serialization
        oslo-utils
        oslotest
        python3Packages
        reno
        ;
    };
    python-cinderclient = python3Packages.python-cinderclient.override {
      inherit
        keystoneauth1
        oslo-i18n
        oslo-serialization
        oslo-utils
        ;
    };
    python-glanceclient = python3Packages.python-glanceclient.override {
      inherit
        keystoneauth1
        oslo-i18n
        oslo-utils
        ;
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
    python-neutronclient = callPackage ./python-neutronclient.nix {
      inherit
        keystoneauth1
        openstacksdk
        os-client-config
        osc-lib
        oslo-i18n
        oslo-log
        oslo-serialization
        oslo-utils
        oslotest
        osprofiler
        python-keystoneclient
        python3Packages
        ;
    };
    python-novaclient = python3Packages.python-novaclient.override {
      inherit
        keystoneauth1
        oslo-i18n
        oslo-serialization
        ;
    };
    python-swiftclient = callPackage ./python-swiftclient.nix {
      inherit
        python-keystoneclient
        keystoneauth1
        openstacksdk
        python3Packages
        ;
    };
    reno = callPackage ./reno.nix { inherit python3Packages; };
    sphinxcontrib-svg2pdfconverter = callPackage ./sphinxcontrib-svg2pdfconverter.nix {
      inherit python3Packages;
    };
    suds-community = callPackage ./suds-community.nix { inherit python3Packages; };
    taskflow = callPackage ./taskflow.nix {
      inherit
        automaton
        etcd3gw
        futurist
        oslo-serialization
        oslo-utils
        oslotest
        pre-commit
        python3Packages
        zake
        ;
    };
    tooz = callPackage ./tooz.nix {
      inherit
        etcd3gw
        futurist
        oslo-serialization
        oslo-utils
        python3Packages
        zake
        ;
    };
    uhashring = callPackage ./uhashring.nix { inherit python3Packages; };
    wsme = python3Packages.wsme.overrideAttrs (old: {
      disabled = false;
      propagatedBuildInputs = old.propagatedBuildInputs ++ [ python3Packages.importlib-metadata ];
    });
    xstatic-angular-bootstrap = callPackage ./xstatic-angular-bootstrap.nix {
      inherit python3Packages;
    };
    xstatic-angular-fileupload = callPackage ./xstatic-angular-fileupload.nix {
      inherit python3Packages;
    };
    xstatic-angular-gettext = callPackage ./xstatic-angular-gettext.nix { inherit python3Packages; };
    xstatic-angular-lrdragndrop = callPackage ./xstatic-angular-lrdragndrop.nix {
      inherit python3Packages;
    };
    xstatic-angular-schema-form = callPackage ./xstatic-angular-schema-form.nix {
      inherit python3Packages;
    };
    xstatic-angular = callPackage ./xstatic-angular.nix { inherit python3Packages; };
    xstatic-bootstrap-datepicker = callPackage ./xstatic-bootstrap-datepicker.nix {
      inherit python3Packages;
    };
    xstatic-bootstrap-scss = callPackage ./xstatic-bootstrap-scss.nix { inherit python3Packages; };
    xstatic-bootswatch = callPackage ./xstatic-bootswatch.nix { inherit python3Packages; };
    xstatic-d3 = callPackage ./xstatic-d3.nix { inherit python3Packages; };
    xstatic-hogan = callPackage ./xstatic-hogan.nix { inherit python3Packages; };
    xstatic-jasmine = callPackage ./xstatic-jasmine.nix { inherit python3Packages; };
    xstatic-jquery-migrate = callPackage ./xstatic-jquery-migrate.nix { inherit python3Packages; };
    xstatic-jquery-quicksearch = callPackage ./xstatic-jquery-quicksearch.nix {
      inherit python3Packages;
    };
    xstatic-jquery-tablesorter = callPackage ./xstatic-jquery-tablesorter.nix {
      inherit python3Packages;
    };
    xstatic-jsencrypt = callPackage ./xstatic-jsencrypt.nix { inherit python3Packages; };
    xstatic-mdi = callPackage ./xstatic-mdi.nix { inherit python3Packages; };
    zake = callPackage ./zake.nix { inherit python3Packages; };
  };
in
{
  default = openstackPkgs.nova;
}
// openstackPkgs
