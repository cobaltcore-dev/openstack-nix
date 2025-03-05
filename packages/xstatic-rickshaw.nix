{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Rickshaw";
  version = "1.5.1.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-zyeNS9TpdN3PcXDSC7twbMNPk89hZY8vaPMTg3QXhWQ=";
  };
}
