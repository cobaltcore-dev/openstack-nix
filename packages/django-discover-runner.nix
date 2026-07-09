{
  fetchPypi,
  python3Packages,
  django,
}:
let
  inherit (python3Packages)
    pip
    setuptools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django-discover-runner";
  version = "1.0";

  pyproject = true;

  nativeBuildInputs = [
    pip
    setuptools
  ];

  propagatedBuildInputs = [
    django
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-C6kf5yLCVry/3rNvrH6sDyflv9pV2YxMHPmrYrWwhP4=";
  };
}
