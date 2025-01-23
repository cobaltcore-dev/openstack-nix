{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-JQuery-Migrate";
  version = "3.3.2.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-mG+Xmg4toKRTQaAzaRgRFH/fbqqXpwa3qz2edxHOrW4=";
  };
}
