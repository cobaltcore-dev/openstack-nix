{
  python3Packages,
  keystoneauth1,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  openssl,
}:
let
  inherit (python3Packages)
    ddt
    iso8601
    pbr
    prettytable
    pythonOlder
    requests-mock
    stestr
    stevedore
    testscenarios
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-novaclient";
  version = "18.7.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-lMrQ8PTBYc7VKl7NhdE0/Wc7mX2nGUoDHAymk0Q0Cw0=";
  };

  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  dependencies = [
    iso8601
    keystoneauth1
    oslo-i18n
    oslo-serialization
    oslo-utils
    pbr
    prettytable
    stevedore
  ];

  nativeCheckInputs = [
    ddt
    openssl
    requests-mock
    stestr
    testscenarios
  ];

  checkPhase = ''
    runHook preCheck
    stestr run -e <(echo "
    novaclient.tests.unit.test_shell.ParserTest.test_ambiguous_option
    novaclient.tests.unit.test_shell.ParserTest.test_not_really_ambiguous_option
    novaclient.tests.unit.test_shell.ShellTest.test_osprofiler
    novaclient.tests.unit.test_shell.ShellTestKeystoneV3.test_osprofiler
    ")
    runHook postCheck
  '';

  pythonImportsCheck = [ "novaclient" ];
}
