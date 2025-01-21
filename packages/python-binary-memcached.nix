{
  fetchPypi,
  python3Packages,
  uhashring,
}:
let
  inherit (python3Packages)
    flake8
    mock
    pytest
    pytest-cov
    six
    trustme
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python_binary_memcached";
  version = "0.31.3";

  propagatedBuildInputs = [
    six
    uhashring
  ];

  checkInputs = [
    flake8
    mock
    pytest
    pytest-cov
    trustme
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-qnx+Go7yej6J9fGCPgTFjYke+CTOjKJrpoO+VGDxfAo=";
  };
}
