{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    black
    flake8
    hatchling
    isort
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "uhashring";
  version = "2.3";
  pyproject = true;

  nativeBuildInputs = [
    black
    flake8
    hatchling
    isort
  ];

  checkPhase = ''
    isort --check-only --diff uhashring
    black -q --check --diff uhashring
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-n3YYfo2OgvblUZyZXu8fG/RNSl4PxP3RIZoESxAEBhI=";
  };
}
