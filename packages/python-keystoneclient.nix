{
  fetchPypi,
  keystoneauth1,
  openssl,
  oslo-config,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    coverage
    debtcollector
    fixtures
    flake8-docstrings
    hacking
    keyring
    lxml
    oauthlib
    packaging
    pbr
    requests
    requests-mock
    stevedore
    stestr
    tempest
    testresources
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-keystoneclient";
  version = "5.5.0";

  nativeBuildInputs = [
    openssl
    pbr
  ];

  propagatedBuildInputs = [
    debtcollector
    keystoneauth1
    oslo-config
    oslo-i18n
    oslo-serialization
    oslo-utils
    packaging
    requests
    stevedore
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    #os-client-config
    bandit
    coverage
    fixtures
    flake8-docstrings
    hacking
    keyring
    lxml
    oauthlib
    oslotest
    requests-mock
    tempest
    testresources
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-wvWTT5VXaTbJjkW/WZrUi8sKxFFZPl+DROv1LLD0EfU=";
  };
}
