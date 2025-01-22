{
  fetchPypi,
  oslo-concurrency,
  oslo-context,
  oslo-i18n,
  oslo-utils,
  pre-commit,
  python3Packages,
  suds-community,
}:
let
  inherit (python3Packages)
    coverage
    ddt
    defusedxml
    eventlet
    fixtures
    hacking
    lxml
    netaddr
    pbr
    pyyaml
    requests
    stevedore
    testtools
    urllib3
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.vmware";
  version = "4.5.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    defusedxml
    eventlet
    lxml
    netaddr
    oslo-concurrency
    oslo-context
    oslo-i18n
    oslo-utils
    pyyaml
    requests
    stevedore
    suds-community
    urllib3
  ];

  checkInputs = [
    coverage
    ddt
    fixtures
    hacking
    pre-commit
    testtools
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-z2y0tuNEargORr4C7gWjXmoAPu1EWsHZZng390HFUU8=";
  };
}
