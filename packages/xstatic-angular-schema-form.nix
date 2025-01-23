{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular-Schema-Form";
  version = "0.8.13.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-fAhjSQF1Emf+JtJm/AJ89u0uX0Imlphc7HUFlLP04wA=";
  };
}
