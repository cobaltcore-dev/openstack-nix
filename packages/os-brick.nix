{
  castellan,
  doc8,
  fetchPypi,
  flake8-logging-format,
  os-win,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-log,
  oslo-privsep,
  oslo-serialization,
  oslo-service,
  oslo-utils,
  oslo-vmware,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    coverage
    ddt
    eventlet
    fixtures
    flake8-import-order
    hacking
    mypy
    pbr
    psutil
    requests
    stestr
    tenacity
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-brick";
  version = "6.9.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
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
    psutil
    requests
    tenacity
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    bandit
    castellan
    coverage
    ddt
    doc8
    eventlet
    fixtures
    flake8-import-order
    flake8-logging-format
    hacking
    mypy
    oslo-vmware
    oslotest
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-lk7Me3wkkmpbbwkjhqLuO97mg+KU17kZDMlR1xFfGV8=";
  };
}
