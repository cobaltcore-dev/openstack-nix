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
    bcrypt
    coverage
    debtcollector
    fixtures
    jinja2
    pbr
    statsd
    stestr
    stevedore
    testtools
    webob
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.middleware";
  version = "6.3.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    bcrypt
    debtcollector
    jinja2
    oslo-config
    oslo-context
    oslo-i18n
    oslo-utils
    statsd
    stevedore
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    oslo-serialization
    oslotest
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Z1kjqDhxVHIiy6HC48LPwzIF275uJVykdEht+7PCI3c=";
  };
}
