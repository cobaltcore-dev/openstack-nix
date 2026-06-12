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
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-resource-classes";
  version = "1.1.0";

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
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-4Ly7iWGp/jO3ITc0xRwAGBKJDivmIQHJJ5yIty91+es=";
  };
}
