{
  fetchPypi,
  keystoneauth1,
  openstacksdk,
  os-client-config,
  osc-lib,
  oslo-i18n,
  oslo-log,
  oslo-serialization,
  oslo-utils,
  oslotest,
  osprofiler,
  python-keystoneclient,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    cliff
    coverage
    debtcollector
    fixtures
    flake8-import-order
    hacking
    iso8601
    netaddr
    pbr
    python-dateutil
    python-openstackclient
    python-subunit
    requests
    requests-mock
    stestr
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-neutronclient";
  version = "11.3.1";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    cliff
    debtcollector
    iso8601
    keystoneauth1
    netaddr
    openstacksdk
    os-client-config
    osc-lib
    oslo-i18n
    oslo-log
    oslo-serialization
    oslo-utils
    python-dateutil
    python-keystoneclient
    requests
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    bandit
    coverage
    fixtures
    flake8-import-order
    hacking
    oslotest
    osprofiler
    python-openstackclient
    python-subunit
    requests-mock
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-U82ZI/Q6OwdypA41YfdGVa3IA4+QJhqz3gW2IR0S7cs=";
  };
}
