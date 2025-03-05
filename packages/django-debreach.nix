{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    setuptools
    pip
    django
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django-debreach";
  version = "2.1.0";

  pyproject = true;

  nativeBuildInputs = [
    setuptools
    pip
  ];

  propagagedBuildInputs = [
    django
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-rqyfQ+Dql4ML7WnLMJrVdGte0rnc5zOsTBNsjhan1uU=";
  };
}
