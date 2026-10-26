{
  fetchPypi,
  oslo-config,
  oslotest,
  ovs,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    eventlet
    hacking
    msgpack
    ncclient
    netaddr
    packaging
    pbr
    pycodestyle
    pylint
    subunit
    routes
    stestr
    testscenarios
    testtools
    webob
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "os-ken";
  version = "3.0.0";

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    eventlet
    msgpack
    ncclient
    netaddr
    oslo-config
    ovs
    packaging
    routes
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    hacking
    oslotest
    pycodestyle
    pylint
    subunit
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    pname = "os_ken";
    inherit version;
    sha256 = "sha256-w1pNBppsz9wW9Vn57CePadoCc5DoRV7sQU4BujR3NM0=";
  };
}
