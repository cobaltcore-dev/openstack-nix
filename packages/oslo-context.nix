{
  fetchPypi,
  python3Packages,
  oslotest,
  pre-commit,
}:
let
  inherit (python3Packages)
    bandit
    coverage
    debtcollector
    fixtures
    hacking
    mypy
    pbr
    stestr
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "oslo.context";
  version = "5.7.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    debtcollector
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    bandit
    coverage
    fixtures
    hacking
    mypy
    oslotest
    pre-commit
  ];

  checkPhase = ''
    stestr run .
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-OYxGC5z3yzl+3nliIj5LiAePsvvFNmWkejThsoiQ9M4=";
  };
}
