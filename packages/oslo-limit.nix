{
  fetchPypi,
  keystoneauth1,
  openstacksdk,
  oslo-config,
  oslo-i18n,
  oslo-log,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    fixtures
    python-dateutil
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.limit";
  version = "2.6.0";

  propagatedBuildInputs = [
    keystoneauth1
    openstacksdk
    oslo-config
    oslo-i18n
    oslo-log
    python-dateutil
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-wSXJSLzUjIPi2unTLn0X4XotK0NI3Q6i1FCXc3hzoXo=";
  };
}
