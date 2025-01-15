{
  fetchPypi,
  oslo-config,
  pre-commit,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    fixtures
    hacking
    python-subunit
    stestr
    testtools
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "oslotest";
  version = "5.0.0";

  nativeCheckInputs = [
    stestr
  ];

  propagatedBuildInputs = [
    fixtures
    python-subunit
    testtools
  ];

  checkInputs = [
    coverage
    hacking
    oslo-config
    pre-commit
  ];

  checkPhase = ''
    stestr run .
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-97skDGy+8voLq7lRP/PafQ8ozDja+Y70Oy6ISDZ/vSA=";
  };
}
