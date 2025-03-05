{
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular";
  version = "1.8.2.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-TIFq1aH5krHWPNKXXjwSYvyghnL1mG4YOKu2TtdcgyM=";
  };
}
