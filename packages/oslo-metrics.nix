{
  fetchPypi,
  oslo-config,
  oslo-log,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    coverage
    hacking
    pbr
    prometheus-client
    python-dateutil
    stestr
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "oslo.metrics";
  version = "0.10.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    oslo-config
    oslo-log
    oslo-utils
    prometheus-client
    python-dateutil
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    bandit
    coverage
    hacking
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;

    sha256 = "sha256-WoYQggznvmj1uFT1lqXERM/e+0hrhIEG5w46Q1jtoJE=";
  };
}
