{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    setuptools
    pip
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "rjsmin";
  version = "1.2.2";

  pyproject = true;

  nativeBuildInputs = [
    setuptools
    pip
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-jBvNghFD/s8jJCAStV4TYQhAqDnNRns1jxY1kBDWLa4=";
  };
}
