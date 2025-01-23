{
  automaton,
  etcd3gw,
  fetchPypi,
  futurist,
  oslo-serialization,
  oslo-utils,
  oslotest,
  pifpaf,
  pre-commit,
  python3Packages,
  zake,
}:
let
  inherit (python3Packages)
    alembic
    cachetools
    eventlet
    fasteners
    hacking
    jsonschema
    kazoo
    kombu
    networkx
    pbr
    psycopg2
    pydot
    pymysql
    redis
    sqlalchemy
    sqlalchemy-utils
    stestr
    tenacity
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "taskflow";
  version = "5.10.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    automaton
    cachetools
    fasteners
    futurist
    jsonschema
    networkx
    oslo-serialization
    oslo-utils
    pydot
    tenacity
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    alembic
    etcd3gw
    eventlet
    hacking
    kazoo
    kombu
    oslotest
    pifpaf
    pre-commit
    psycopg2
    pymysql
    redis
    sqlalchemy
    sqlalchemy-utils
    testscenarios
    testtools
    zake
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-9C/DMOusiBTNjD8bJDrg9GpZnHg/NyR9ojazWUfo37g=";
  };
}
