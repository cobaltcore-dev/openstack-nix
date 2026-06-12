{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    django
    pyscss
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django-pyscss";
  version = "2.0.3";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  propagatedBuildInputs = [
    django
    pyscss
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-uXbDV1eWIL8hoQFSqGPTD2a7YozU+Z3vlZVfyFgeNtI=";
  };
}
