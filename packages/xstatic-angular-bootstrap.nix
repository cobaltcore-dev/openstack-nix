{
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular-Bootstrap";
  version = "2.5.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-vmBobJopx0zurdeHlpwry8458Vsw2qSUlXSuymAvnzU=";
  };
}
