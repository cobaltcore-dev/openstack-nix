{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-objectpath";
  version = "1.2.1.0";

  src = fetchPypi {
    inherit pname version;

    sha256 = "sha256-zR6fUCSCr83QKIIRSIQ7B7QGXI3OqOXMM6u5rhzyCyA=";
  };
}
