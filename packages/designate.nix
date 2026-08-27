{
  fetchPypi,
  libredirect,
  futurist,
  infoblox-client,
  keystoneauth1,
  keystonemiddleware,
  openstacksdk,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-db,
  oslo-i18n,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-policy,
  oslo-reports,
  oslo-rootwrap,
  oslo-serialization,
  oslo-service,
  oslo-upgradecheck,
  oslo-utils,
  oslo-versionedobjects,
  oslotest,
  osprofiler,
  python-designateclient,
  python3Packages,
  sqlalchemy,
  tooz,
  writeScript,
  lib,
}:
let
  inherit (python3Packages)
    alembic
    dnspython
    eventlet
    flask
    greenlet
    jinja2
    jsonschema
    paste
    pastedeploy
    pbr
    pecan
    pymysql
    python-memcached
    requests
    requests-mock
    stestr
    stevedore
    tenacity
    testresources
    testscenarios
    webob
    webtest
    ;

  testExcludes = [
    "designate.tests.unit.backend.test_infoblox.*"
  ];

  excludeListFile = writeScript "test_excludes" (lib.concatStringsSep "\n" testExcludes);

in
python3Packages.buildPythonPackage (rec {
  pname = "designate";
  version = "19.1.0";
  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  postPatch = ''
    cp ${./designate-knot3-backend.py} designate/backend/impl_knot3.py
    substituteInPlace setup.cfg \
      --replace-fail \
        "infoblox = designate.backend.impl_infoblox:InfobloxBackend" \
        $'infoblox = designate.backend.impl_infoblox:InfobloxBackend\n\tknot3 = designate.backend.impl_knot3:Knot3Backend'
  '';

  propagatedBuildInputs = [
    (alembic.override { inherit sqlalchemy; })
    dnspython
    eventlet
    flask
    futurist
    greenlet
    infoblox-client
    jinja2
    jsonschema
    keystoneauth1
    keystonemiddleware
    openstacksdk
    oslo-concurrency
    oslo-config
    oslo-context
    oslo-db
    oslo-i18n
    oslo-log
    oslo-messaging
    oslo-middleware
    oslo-policy
    oslo-reports
    oslo-rootwrap
    oslo-serialization
    oslo-service
    oslo-upgradecheck
    oslo-utils
    oslo-versionedobjects
    oslotest
    osprofiler
    paste
    pastedeploy
    pbr
    pecan
    pymysql
    python-designateclient
    python-memcached
    requests
    sqlalchemy
    stevedore
    tenacity
    tooz
    webob
  ];

  nativeCheckInputs = [
    libredirect.hook
    stestr
  ];

  checkInputs = [
    oslotest
    requests-mock
    testresources
    testscenarios
    webtest
  ];

  checkPhase = ''
    runHook preCheck
    echo "nameserver 127.0.0.1" > resolv.conf
    export NIX_REDIRECTS="/etc/resolv.conf=$(realpath resolv.conf)"
    stestr run --exclude-list ${excludeListFile}
    runHook postCheck
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-kqZJRM9WX8nXxEi+8KuBotwkIk8kVlpvDgp+3czDSeE=";
  };
})
