{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular-Gettext";
  version = "2.4.1.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-iDGSySc7LRuNxp5gWEXw06JnaYlV5V3N4OOk3v6uOFs=";
  };
}
