{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Jasmine";
  version = "2.4.1.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-v5Ib5CPCVKXOvCFWp/1m2CEM79JR/C+lH3kqFTv56Cs=";
  };
}
