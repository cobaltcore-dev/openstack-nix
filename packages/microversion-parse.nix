{
  fetchPypi,
  gabbi,
  pre-commit,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    hacking
    stestr
    testtools
    webob
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "microversion_parse";
  version = "2.0.0";

  nativeBuildInputs = [
    pre-commit
  ];

  propagatedBuildInputs = [
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    hacking
    gabbi
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-OmUo7fc/O8tFB/Ta09vDEW6XBIFe373W/wbcX4macdw=";
  };
}
