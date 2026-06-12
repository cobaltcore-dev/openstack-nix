{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-bootswatch";
  version = "3.3.7.0";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-k+5YY8HsByEv4SrhN6EHCLQQJyA5HUYPBh3T9EG6O24=";
  };
}
