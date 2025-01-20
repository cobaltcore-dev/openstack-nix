{
  fetchPypi,
  oslo-concurrency,
  oslo-config,
  oslo-i18n,
  oslo-log,
  oslo-utils,
  oslotest,
  procps,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    debtcollector
    eventlet
    fixtures
    greenlet
    paste
    pastedeploy
    pbr
    python-dateutil
    requests
    routes
    stestr
    webob
    yappi
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.service";
  version = "3.6.0";

  nativeBuildInputs = [
    pbr
    procps
  ];

  propagatedBuildInputs = [
    debtcollector
    eventlet
    greenlet
    oslo-concurrency
    oslo-config
    oslo-i18n
    oslo-log
    oslo-utils
    paste
    pastedeploy
    routes
    webob
    yappi
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    oslotest
    python-dateutil
    requests
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-MkhzZ7scUcBlRhgCHDdUpqCBFRooANluzPzkkSNWpjo=";
  };
}
