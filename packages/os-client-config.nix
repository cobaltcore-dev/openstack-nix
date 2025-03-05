{
  fetchPypi,
  openstacksdk,
  oslotest,
  python-glanceclient,
  python3Packages,
}:
let
  inherit (python3Packages)
    stestr
    hacking
    coverage
    fixtures
    jsonschema
    python-subunit
    testtools
    testscenarios
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-client-config";
  version = "2.1.0";

  propagatedBuildInputs = [
    openstacksdk
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    hacking
    jsonschema
    oslotest
    python-glanceclient
    python-subunit
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-q8OKNR+MAG009+5fP2SN5ePs9kVcxdds/YidKRzfP04=";
  };
}
