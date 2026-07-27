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
    extras
    fixtures
    jsonschema
    subunit
    testtools
    testscenarios
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-client-config";
  version = "2.1.0";

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  propagatedBuildInputs = [
    openstacksdk
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    extras
    fixtures
    hacking
    jsonschema
    oslotest
    python-glanceclient
    subunit
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
