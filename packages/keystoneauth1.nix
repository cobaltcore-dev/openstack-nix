{
  fetchPypi,
  oslo-config,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    betamax
    coverage
    fixtures
    flake8-docstrings
    flake8-import-order
    hacking
    iso8601
    lxml
    oauthlib
    os-service-types
    pbr
    pyyaml
    requests
    requests-kerberos
    requests-mock
    stestr
    stevedore
    testresources
    testtools
    typing-extensions
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "keystoneauth1";
  version = "5.8.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    iso8601
    requests
    stevedore
    typing-extensions
    os-service-types
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    bandit
    betamax
    coverage
    fixtures
    flake8-docstrings
    flake8-import-order
    hacking
    lxml
    oauthlib
    oslo-config
    oslo-utils
    oslotest
    pyyaml
    requests-kerberos
    requests-mock
    testresources
    testtools
  ];

  checkPhase = ''
    stestr run . --exclude-regex test_keystoneauth_betamax_fixture
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-MVfCEuEhFk3mTWPl734dqtK9NkmmjeHpcbdodwGe8cQ=";
  };
}
