{
  fetchPypi,
  oslotest,
  ovs,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    fixtures
    isort
    netaddr
    pbr
    pythonRelaxDepsHook
    python-subunit
    stestr
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "ovsdbapp";
  version = "2.9.0";

  nativeBuildInputs = [
    pbr
    pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [ "isort" ];

  propagatedBuildInputs = [
    fixtures
    netaddr
    ovs
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    isort
    oslotest
    python-subunit
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-gEXFbAFe+ukmu5uejyLCQ1xI6heCCVaouHlAgYqoYH8=";
  };
}
