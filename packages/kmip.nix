{
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "PyKMIP";
  version = "0.10.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-u2/zELuosRMP/mdTR/Zo9yNNAiuj1R7epep+LqlSOJc=";
  };
}
