{
  fetchPypi,
  keystoneauth1,
  oslo-cache,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-log,
  oslo-messaging,
  oslo-serialization,
  oslo-utils,
  oslotest,
  pycadf,
  python-keystoneclient,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    coverage
    cryptography
    fixtures
    flake8-docstrings
    hacking
    pbr
    pyjwt
    python-memcached
    requests
    requests-mock
    stestr
    stevedore
    testresources
    testtools
    webob
    webtest
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "keystonemiddleware";
  version = "10.8.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    keystoneauth1
    oslo-cache
    oslo-config
    oslo-context
    oslo-i18n
    oslo-log
    oslo-serialization
    oslo-utils
    pycadf
    pyjwt
    python-keystoneclient
    requests
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    hacking
    flake8-docstrings
    coverage
    cryptography
    fixtures
    oslotest
    stevedore
    requests-mock
    stestr
    testresources
    testtools
    python-memcached
    webtest
    oslo-messaging
    pyjwt
    bandit
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-oV5Vxy2tYIRm96mtEMWLEYIWsMOX1AJRetJvPU4RsKQ=";
  };
}
