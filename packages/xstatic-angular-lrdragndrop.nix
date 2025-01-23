{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular-lrdragndrop";
  version = "1.0.2.6";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-j2cJXpbA1K2Vz2k4xltAnODmEDbPpEo80HRHlLs7BQE=";
  };
}
