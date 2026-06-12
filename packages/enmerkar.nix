{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    babel
    django
    pytest
    pytest-cov
    pytest-django
    setuptools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "enmerkar";
  version = "0.7.1";

  pyproject = true;
  build-system = [ setuptools ];

  nativeBuildInputs = [
    babel
    django
  ];

  nativeCheckInputs = [
    pytest
    pytest-cov
    pytest-django
  ];

  src = fetchPypi {
    inherit version pname;

    sha256 = "sha256-pKbIWbTtKT3u5A/2HWaVs/97wVN3CheZ8r6HIYEoLgA=";
  };
}
