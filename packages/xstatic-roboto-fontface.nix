{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-roboto-fontface";
  version = "0.5.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-bSct9Y4g7sOhW8onkWPzhhTHB04v7LU3pYsp0QnoP2I=";
  };
}
