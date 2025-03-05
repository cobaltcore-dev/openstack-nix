{
  fetchPypi,
  keystoneauth1,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-log,
  oslo-utils,
  oslotest,
  pifpaf,
  python-barbicanclient,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    cryptography
    fixtures
    pbr
    python-dateutil
    python-subunit
    requests
    requests-mock
    stestr
    stevedore
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "castellan";
  version = "5.1.1";

  nativeBuildInputs = [
    pbr
    pifpaf
  ];

  propagatedBuildInputs = [
    cryptography
    keystoneauth1
    oslo-config
    oslo-context
    oslo-i18n
    oslo-log
    oslo-utils
    python-barbicanclient
    python-dateutil
    requests
    stevedore
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    oslotest
    python-barbicanclient
    python-subunit
    requests-mock
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-eZPOpkc4OuAsgYFtdesiwqQoDi0bmLHij//UD8bYuy8=";
  };
}
