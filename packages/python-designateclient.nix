{
  fetchPypi,
  keystoneauth1,
  osc-lib,
  oslo-config,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
  reno,
}:
let
  inherit (python3Packages)
    cliff
    coverage
    debtcollector
    hacking
    jsonschema
    python-subunit
    requests
    requests-mock
    stestr
    stevedore
    tempest
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-designateclient";
  version = "6.1.0";

  propagatedBuildInputs = [
    cliff
    debtcollector
    jsonschema
    keystoneauth1
    osc-lib
    oslo-serialization
    oslo-utils
    requests
    stevedore
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    hacking
    oslo-config
    oslotest
    python-subunit
    reno
    requests-mock
    tempest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-GtwqB0sw2ELPl4f1MxDDeUkZW/TjTaOYTlY1t7ikaJw=";
  };
}
