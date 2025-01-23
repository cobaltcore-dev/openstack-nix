{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    django
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django-discover-runner";
  version = "1.0";

  propagatedBuildInputs = [
    django
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-C6kf5yLCVry/3rNvrH6sDyflv9pV2YxMHPmrYrWwhP4=";
  };
}
