{
  fetchPypi,
  oslo-config,
  oslo-context,
  oslo-i18n,
  oslo-utils,
  oslotest,
  pifpaf,
  pre-commit,
  python3Packages,
  sqlalchemy,
}:
let
  inherit (python3Packages)
    alembic
    bandit
    coverage
    debtcollector
    eventlet
    fixtures
    hacking
    psycopg2
    pymysql
    subunit
    stestr
    stevedore
    testresources
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.db";
  version = "17.0.0";

  propagatedBuildInputs = [
    (alembic.override { inherit sqlalchemy; })
    debtcollector
    oslo-config
    oslo-i18n
    oslo-utils
    sqlalchemy
    stevedore
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    bandit
    coverage
    eventlet
    fixtures
    hacking
    oslo-context
    oslotest
    pifpaf
    pre-commit
    psycopg2
    pymysql
    subunit
    testresources
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-nPG6nkO0u73nmUZBr20GxF9xEqfhR28U3QsnuajrEH0=";
  };
}
