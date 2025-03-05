{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-D3";
  version = "3.5.17.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-F26T7ucZLgf8VDNN2xprZPz8jN5quyP2VyeFa7ndGCk=";
  };
}
