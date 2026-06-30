{
  castellan,
  cursive,
  fetchPypi,
  keystoneauth1,
  keystonemiddleware,
  lib,
  os-brick,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-db,
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
  oslo-vmware,
  oslotest,
  osprofiler,
  python-glanceclient,
  python-keystoneclient,
  python-novaclient,
  python-openstackclient,
  python-swiftclient,
  python3Packages,
  qemu-utils,
  taskflow,
  tooz,
  writeScript,
}:
let
  inherit (python3Packages)
    ddt
    distro
    eventlet
    google-api-python-client
    hacking
    moto
    paramiko
    pbr
    pycodestyle
    pymysql
    python-memcached
    rtslib-fb
    sqlalchemy-utils
    stestr
    tabulate
    tenacity
    testresources
    testscenarios
    zstd
    ;

  testExcludes = [
    "cinder.tests.unit.volume.drivers.datacore.test_datacore_api.DataCoreClientTestCase.*"
  ];

  excludeListFile = writeScript "test_excludes" (lib.concatStringsSep "\n" testExcludes);
in
python3Packages.buildPythonPackage rec {
  pname = "cinder";
  version = "25.0.0";

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    castellan
    cursive
    ddt
    distro
    eventlet
    keystoneauth1
    keystonemiddleware
    os-brick
    oslo-concurrency
    oslo-config
    oslo-context
    oslo-db
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
    oslo-vmware
    osprofiler
    pymysql
    python-glanceclient
    python-keystoneclient
    python-memcached
    python-novaclient
    python-openstackclient
    python-swiftclient
    qemu-utils
    rtslib-fb
    tabulate
    taskflow
    tenacity
    tooz
    zstd
  ];

  nativeCheckInputs = [
    google-api-python-client
    hacking
    moto
    oslotest
    paramiko
    pycodestyle
    qemu-utils
    sqlalchemy-utils
    stestr
    testresources
    testscenarios
  ];

  checkInputs = [
  ];

  checkPhase = ''
    stestr run --exclude-list ${excludeListFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-buuMVplVemxjPbMsOsFVVwsKsH6OYiKpv6FtKup5NsU=";
  };

}
