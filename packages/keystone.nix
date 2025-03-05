{
  fetchPypi,
  keystonemiddleware,
  oslo-cache,
  oslo-db,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-policy,
  oslo-serialization,
  oslo-upgradecheck,
  oslotest,
  osprofiler,
  python-keystoneclient,
  python3Packages,
  which,
}:
let
  inherit (python3Packages)
    bandit
    bcrypt
    cryptography
    flask
    flask-restful
    freezegun
    hacking
    jsonschema
    ldap
    ldappool
    lxml
    oauthlib
    passlib
    pbr
    py_scrypt
    pycodestyle
    pymysql
    pysaml2
    requests
    sqlalchemy
    stestr
    tempest
    testresources
    testscenarios
    testtools
    webob
    webtest
    ;
in
python3Packages.buildPythonPackage (rec {
  pname = "keystone";
  version = "26.0.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    bcrypt
    cryptography
    flask
    flask-restful
    jsonschema
    keystonemiddleware
    oauthlib
    oslo-cache
    oslo-db
    oslo-log
    oslo-messaging
    oslo-middleware
    oslo-policy
    oslo-serialization
    oslo-upgradecheck
    osprofiler
    passlib
    py_scrypt
    pymysql
    pysaml2
    python-keystoneclient
    sqlalchemy
    webob
  ];

  nativeCheckInputs = [
    oslo-policy
    stestr
    which
  ];

  checkInputs = [
    bandit
    freezegun
    hacking
    ldap
    ldappool
    lxml
    oslo-db
    oslotest
    pycodestyle
    requests
    tempest
    testresources
    testscenarios
    testtools
    webtest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-dUFsKwu17C7eFsvGMuRA+Vsd7U/bBvixZrolwXGv1+k=";
  };
})
