{
  openstacksdk,
  osc-lib,
  oslo-i18n,
  python-cinderclient,
  python-designateclient,
  python-keystoneclient,
  python3Packages,
}:
let
  inherit (python3Packages)
    ddt
    cliff
    cryptography
    iso8601
    pbr
    pythonOlder
    requests
    requests-mock
    stestr
    stevedore
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python_openstackclient";
  version = "8.0.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-W3peBok/gztdKW0BnFDULHNo43dI7mvo6bFWVbmZQk4=";
  };

  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  dependencies = [
    cliff
    cryptography
    iso8601
    openstacksdk
    osc-lib
    oslo-i18n
    pbr
    python-cinderclient
    python-designateclient
    python-keystoneclient
    requests
    stevedore
  ];

  checkInputs = [
    ddt
    requests-mock
    stestr
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkPhase = ''
    stestr run --exclude-regex test_endpoint_list_project_with_project_domain
  '';
}
