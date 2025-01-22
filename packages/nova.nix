{
  castellan,
  cursive,
  fetchPypi,
  futurist,
  gabbi,
  keystoneauth1,
  keystonemiddleware,
  lib,
  microversion-parse,
  openssl,
  openstacksdk,
  os-brick,
  os-resource-classes,
  os-traits,
  os-vif,
  oslo-cache,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-db,
  oslo-i18n,
  oslo-limit,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-policy,
  oslo-privsep,
  oslo-reports,
  oslo-rootwrap,
  oslo-serialization,
  oslo-service,
  oslo-upgradecheck,
  oslo-utils,
  oslo-versionedobjects,
  oslotest,
  osprofiler,
  python-barbicanclient,
  python-cinderclient,
  python-glanceclient,
  python-neutronclient,
  python3Packages,
  tooz,
  writeScript,
}:
let
  inherit (python3Packages)
    alembic
    bandit
    coverage
    cryptography
    ddt
    decorator
    eventlet
    fixtures
    greenlet
    hacking
    iso8601
    jinja2
    jsonschema
    libvirt
    lxml
    netaddr
    netifaces
    os-service-types
    paramiko
    paste
    pastedeploy
    pbr
    prettytable
    psutil
    psycopg2
    pymysql
    python-dateutil
    python-memcached
    pyyaml
    requests
    requests-mock
    retrying
    rfc3986
    routes
    sqlalchemy
    stestr
    stevedore
    testresources
    testscenarios
    testtools
    webob
    websockify
    wsgi-intercept
    ;

  testExcludes = [
    "test_inject_admin_password"
    "test_server_pool_waitall"
    "test_validation_errors_19_traits_multiple_additional_traits_two_invalid"
  ];

  excludeListFile = writeScript "test_excludes" (lib.concatStringsSep "\n" testExcludes);
in
python3Packages.buildPythonPackage (rec {
  pname = "nova";
  version = "30.0.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    alembic
    castellan
    cryptography
    cursive
    decorator
    eventlet
    futurist
    greenlet
    iso8601
    jinja2
    jsonschema
    keystoneauth1
    keystonemiddleware
    libvirt
    lxml
    microversion-parse
    netaddr
    netifaces
    openstacksdk
    os-brick
    os-resource-classes
    os-service-types
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
    paramiko
    paste
    pastedeploy
    prettytable
    psutil
    pymysql
    python-barbicanclient
    python-cinderclient
    python-dateutil
    python-glanceclient
    python-memcached
    python-neutronclient
    pyyaml
    requests
    retrying
    rfc3986
    routes
    sqlalchemy
    stevedore
    tooz
    webob
    websockify
  ];

  nativeCheckInputs = [
    openssl
    stestr
  ];

  checkInputs = [
    bandit
    coverage
    ddt
    fixtures
    gabbi
    hacking
    oslotest
    osprofiler
    psycopg2
    requests-mock
    testresources
    testscenarios
    testtools
    wsgi-intercept
  ];

  checkPhase = ''
    substituteInPlace nova/tests/unit/test_api_validation.py --replace-fail "''' is too short" "''' should be non-empty"
    substituteInPlace nova/tests/unit/api/openstack/compute/test_keypairs.py --replace-fail "is too short" "should be non-empty"
    substituteInPlace nova/tests/unit/api/openstack/compute/test_servers.py --replace-fail "is too short" "should be non-empty"
    substituteInPlace nova/tests/unit/compute/provider_config_data/v1/validation_error_test_data.yaml --replace-fail "''' is too short" "''' should be non-empty"
    stestr run --exclude-list ${excludeListFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-CvxHrKGalX/9FMFVX14Bm47sjgqQNgfVX6Odf2IMgqQ=";
  };
})
