{
  alembic,
  castellan,
  fetchPypi,
  keystonemiddleware,
  kmip,
  microversion-parse,
  oslo-config,
  oslo-context,
  oslo-db,
  oslo-i18n,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-policy,
  oslo-serialization,
  oslo-service,
  oslo-upgradecheck,
  oslo-utils,
  oslo-versionedobjects,
  oslotest,
  python3Packages,
  sqlalchemy,
}:
let
  inherit (python3Packages)
    cffi
    hacking
    jsonschema
    ldap3
    pbr
    pecan
    pycodestyle
    pymysql
    python-memcached
    stestr
    webob
    webtest
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "barbican";
  version = "20.0.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    alembic
    castellan
    cffi
    hacking
    jsonschema
    keystonemiddleware
    kmip
    ldap3
    microversion-parse
    oslo-config
    oslo-context
    oslo-db
    oslo-i18n
    oslo-log
    oslo-messaging
    oslo-middleware
    oslo-policy
    oslo-serialization
    oslo-service
    oslo-upgradecheck
    oslo-utils
    oslo-versionedobjects
    oslotest
    pecan
    pycodestyle
    pymysql
    python-memcached
    sqlalchemy
    webob
    webtest
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-pqUtjOMZ1Q5cNko+124d7Vob1vz2xf0wOV8Mudtjmqs=";
  };

}
