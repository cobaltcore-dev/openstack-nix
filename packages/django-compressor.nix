{
  django-appconf,
  django,
  fetchPypi,
  python3Packages,
  rcssmin,
  rjsmin,
}:
let
  inherit (python3Packages)
    setuptools
    pip
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django_compressor";
  version = "4.5";

  pyproject = true;

  nativeBuildInputs = [
    pip
    setuptools
  ];

  propagatedBuildInputs = [
    django
    django-appconf
    rcssmin
    rjsmin
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-nZjJBbdBvmywmtgowdIqn/kkTdCII+KSavjd0YccPGU=";
  };
}
