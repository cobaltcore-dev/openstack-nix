{
  fetchPypi,
  keystonemiddleware,
  microversion-parse,
  os-resource-classes,
  os-traits,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-db,
  oslo-log,
  oslo-middleware,
  oslo-serialization,
  oslo-upgradecheck,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    jsonschema
    pbr
    pymysql
    routes
    sqlalchemy
    stestr
    ;
in
python3Packages.buildPythonPackage (rec {
  pname = "openstack-placement";
  version = "12.0.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    jsonschema
    keystonemiddleware
    microversion-parse
    os-resource-classes
    os-traits
    oslo-concurrency
    oslo-config
    oslo-context
    oslo-db
    oslo-log
    oslo-middleware
    oslo-serialization
    oslo-upgradecheck
    oslo-utils
    pymysql
    routes
    sqlalchemy
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    oslotest
  ];

  checkPhase = ''
    substituteInPlace placement/tests/unit/cmd/test_manage.py --replace-fail "choose from 'db'" "choose from db"
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-DCA7PMCnVKKq6ckdx+6n11jZuNG5LY4BySRXWqWF7qo=";
  };
})
