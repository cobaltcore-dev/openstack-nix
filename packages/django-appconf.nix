{
  django,
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    setuptools
    pip
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django-appconf";
  version = "1.1.0";

  pyproject = true;

  nativeBuildInputs = [
    setuptools
    pip
  ];

  propagatedBuildInputs = [
    django
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-n86tNy+CoPIe4YlDTnrpwAfLsprxEYwYJRcg89BiQ+Q=";
  };
}
