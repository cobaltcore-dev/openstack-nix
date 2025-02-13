{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Font-Awesome";
  version = "4.7.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-4B+0gMqqfHlj3LMyikcA5jG+9gcNsOi2hYFtIg5oX2w=";
  };
}
