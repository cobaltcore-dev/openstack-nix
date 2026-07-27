{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-tv4";
  version = "1.2.7.0";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-m0xXJE6RQSbN2l2LwkaYGJ1zgAIDyFsfyUWgjiXHxxM=";
  };
}
