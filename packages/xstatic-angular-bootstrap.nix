{
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular-Bootstrap";
  version = "2.5.0.0";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-vmBobJopx0zurdeHlpwry8458Vsw2qSUlXSuymAvnzU=";
  };
}
