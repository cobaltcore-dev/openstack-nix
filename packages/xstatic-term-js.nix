{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-term.js";
  version = "0.0.7.0";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-tfOractjg5HwQlSROhGyqrCOLVHFuBu2pWTFptRCvTE=";
  };
}
