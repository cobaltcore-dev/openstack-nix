{
  fetchPypi,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-log,
  oslo-messaging,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    fixtures
    iso8601
    jsonschema
    netaddr
    stestr
    testtools
    webob
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.versionedobjects";
  version = "3.5.0";

  propagatedBuildInputs = [
    iso8601
    netaddr
    oslo-concurrency
    oslo-config
    oslo-context
    oslo-i18n
    oslo-log
    oslo-messaging
    oslo-serialization
    oslo-utils
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    jsonschema
    oslotest
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-QuSsYcjDEx2GLjKD8rP9mKbMBDIKNCFLNKHRpBKKAbA=";
  };
}
