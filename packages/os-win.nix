{
  fetchPypi,
  oslo-concurrency,
  oslo-config,
  oslo-log,
  oslo-utils,
  oslo-i18n,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    ddt
    eventlet
    hacking
    pbr
    python-dateutil
    pythonRelaxDepsHook
    stestr
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-win";
  version = "5.9.0";

  nativeBuildInputs = [
    pbr
    pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [ "hacking" ];

  propagatedBuildInputs = [
    eventlet
    oslo-concurrency
    oslo-config
    oslo-i18n
    oslo-log
    oslo-utils
    python-dateutil
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    ddt
    hacking
    oslotest
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-TUrVEiBgzdExLWkJkhxygMcVn6aBGpZvoRaI/BQYCMA=";
  };
}
