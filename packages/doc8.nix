{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    docutils
    pygments
    restructuredtext-lint
    setuptools_scm
    stevedore
    tomli
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "doc8";
  version = "1.1.2";
  pyproject = true;

  nativeBuildInputs = [
    setuptools_scm
  ];

  propagatedBuildInputs = [
    docutils
    pygments
    restructuredtext-lint
    stevedore
    tomli
  ];

  src = fetchPypi {
    inherit version pname;
    sha256 = "sha256-EiXzAUThzJfjiNuvf+PpltKJdHOlOm2uJo3d4hw1S5g=";
  };
}
