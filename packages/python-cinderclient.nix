{
  python3Packages,
  keystoneauth1,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  reno,
}:
let
  inherit (python3Packages)
    ddt
    pbr
    requests
    openstackdocstheme
    prettytable
    pythonOlder
    requests-mock
    setuptools
    simplejson
    sphinxHook
    stestr
    stevedore
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-cinderclient";
  version = "9.6.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-P+/eJoJS5S4w/idz9lgienjG3uN4/LEy0xyG5uybojg=";
  };

  nativeBuildInputs = [
    openstackdocstheme
    reno
    sphinxHook
  ];

  sphinxBuilders = [ "man" ];

  build-system = [ setuptools ];

  dependencies = [
    simplejson
    keystoneauth1
    oslo-i18n
    oslo-utils
    pbr
    prettytable
    requests
    stevedore
  ];

  nativeCheckInputs = [
    ddt
    oslo-serialization
    requests-mock
    stestr
  ];

  checkPhase = ''
    runHook preCheck
    stestr run --exclude-regex test_load_versioned_actions_with_help
    runHook postCheck
  '';

  pythonImportsCheck = [ "cinderclient" ];
}
