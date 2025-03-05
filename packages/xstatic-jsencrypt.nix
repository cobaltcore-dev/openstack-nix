{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-JSEncrypt";
  version = "2.3.1.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-oneRKk9w0dL1jI2UuZLSROafz4UaLL7V2Dy0/EIqcvI=";
  };
}
