{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    typing-extensions
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "sqlalchemy";
  version = "2.0.34";

  pyproject = true;
  build-system = [
    python3Packages.cython
    python3Packages.setuptools
  ];

  propagatedBuildInputs = [
    typing-extensions
  ];

  nativeCheckInputs = [
  ];

  checkInputs = [
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ENjzaZDdkpaQZmZ5sPQiNcFZpwUVNK2xNXKO5Sgo3SI=";
  };
}
