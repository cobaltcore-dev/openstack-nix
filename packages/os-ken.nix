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
  version = "2.11.2";

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
    inherit pname version;
    sha256 = "sha256-zGB2+83OVCbNBElOHgViZ4SCXl/exLp1eVroDeEkIyA=";
  };
}
