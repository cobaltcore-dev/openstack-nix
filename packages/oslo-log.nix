{
  fetchPypi,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    eventlet
    fixtures
    pbr
    python-dateutil
    stestr
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.log";
  version = "6.2.0";

  nativeBuildInputs = [
    pbr
    python-dateutil
  ];

  propagatedBuildInputs = [
    oslo-config
    oslo-context
    oslo-i18n
    oslo-serialization
    oslo-utils
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    eventlet
    fixtures
    oslotest
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-KxUdnD8rLswSwG0Pt9vy6QR6/a7DZEgn+h4Qs1Q2lWM=";
  };
}
