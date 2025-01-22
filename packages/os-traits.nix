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
  version = "3.2.0";

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
    sha256 = "sha256-NVr3coxNz8Ws4N2DVEX94r928pk7DGyxy7S/c4mDABU=";
  };
}
