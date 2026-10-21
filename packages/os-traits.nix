{
  fetchPypi,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    hacking
    pbr
    stestr
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-traits";
  version = "3.3.0";

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
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
    sha256 = "sha256-IBUOQG+mk6I9H7HFGNGyoS9JV8JWGrwi9zOtXTxreOE=";
  };
}
