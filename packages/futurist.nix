{
  fetchPypi,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    eventlet
    pbr
    prettytable
    python-subunit
    stestr
    testscenarios
    testtools
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "futurist";
  version = "3.0.0";

  nativeBuildInputs = [
    pbr
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    eventlet
    oslotest
    prettytable
    python-subunit
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ZCIBF5JBTDkijhFL7FSUMDqvBtzTNeT43U+Qf3ikH3k=";
  };
}
