{
  fetchPypi,
  keystoneauth1,
  os-ken,
  os-traits,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-db,
  oslo-i18n,
  oslo-log,
  oslo-messaging,
  oslo-policy,
  oslo-serialization,
  oslo-service,
  oslo-utils,
  oslo-versionedobjects,
  oslotest,
  osprofiler,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    ddt
    fixtures
    flake8-import-order
    hacking
    isort
    netaddr
    pbr
    pecan
    pylint
    python-subunit
    setproctitle
    sqlalchemy
    stestr
    stevedore
    testresources
    testscenarios
    testtools
    webob
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "neutron-lib";
  version = "3.16.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    keystoneauth1
    netaddr
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
    osprofiler
    pecan
    setproctitle
    sqlalchemy
    stevedore
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    ddt
    fixtures
    flake8-import-order
    hacking
    isort
    oslotest
    pylint
    python-subunit
    testresources
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-dvqSqJfR/zwxOZRA1P4ASPpg+hXTRX0GA3dCIwDP/ZI=";
  };
}
