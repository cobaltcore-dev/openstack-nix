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
  sqlalchemy,
}:
let
  inherit (python3Packages)
    jsonschema
    pbr
    pymysql
    routes
    stestr
    ;
in
python3Packages.buildPythonPackage (rec {
  pname = "openstack-placement";
  version = "13.0.0";
  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

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
    # Newer Python versions quote argparse choices again.
    substituteInPlace placement/tests/unit/cmd/test_manage.py \
      --replace-fail 'message = "choose from db"' "message = \"choose from 'db'\""
    stestr run
  '';

  src = fetchPypi {
    pname = "openstack_placement";
    inherit version;
    sha256 = "sha256-egR3mjssA0CdX75+wSAt0DD4Ftw5Sw6ZcI1mA2zbyq8=";
  };
})
