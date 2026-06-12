{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-JQuery-Migrate";
  version = "3.3.2.1";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-mG+Xmg4toKRTQaAzaRgRFH/fbqqXpwa3qz2edxHOrW4=";
  };
}
