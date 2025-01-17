{
  fetchPypi,
  oslo-config,
  oslo-i18n,
  oslotest,
  python3Packages,
  qemu,
}:
let
  inherit (python3Packages)
    coverage
    ddt
    debtcollector
    eventlet
    fixtures
    iso8601
    netaddr
    packaging
    pbr
    psutil
    pyparsing
    pyyaml
    stestr
    testscenarios
    testtools
    tzdata
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.utils";
  version = "7.4.0";

  nativeBuildInputs = [
    pbr
    qemu
  ];

  propagatedBuildInputs = [
    debtcollector
    iso8601
    netaddr
    oslo-i18n
    packaging
    psutil
    pyparsing
    pyyaml
    tzdata
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    ddt
    eventlet
    fixtures
    oslo-config
    oslotest
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run .
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ql3LXaoF3fS1NPLN7aVvfyFIXJb1y69qjAhx2AO3Ps4=";
  };
}
