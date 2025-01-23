{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Bootstrap-SCSS";
  version = "3.4.1.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-XLVvAJDLZInWQ3MN5Xxo2KZxTyuf5Sasibto9dd9/hA=";
  };
}
