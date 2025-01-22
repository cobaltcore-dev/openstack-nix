{
  fetchPypi,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    pyyaml
    requests
    requests-mock
    sphinx
    stestr
    stevedore
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.policy";
  version = "4.4.0";

  propagatedBuildInputs = [
    oslo-config
    oslo-context
    oslo-i18n
    oslo-serialization
    oslo-utils
    pyyaml
    requests
    stevedore
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    oslotest
    requests-mock
    sphinx
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-LV9QyLq8vLgOHuQLKv+3y0ZGUP37HZZUoU3fWxk2mcU=";
  };
}
