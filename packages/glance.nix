{
  castellan,
  cursive,
  fetchPypi,
  glance-store,
  keystoneauth1,
  keystonemiddleware,
  os-brick,
  os-win,
  oslo-db,
  oslo-i18n,
  oslo-limit,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-policy,
  oslo-reports,
  oslo-upgradecheck,
  osprofiler,
  python-cinderclient,
  python3Packages,
  qemu,
  taskflow,
  wsme,
}:
let
  inherit (python3Packages)
    defusedxml
    httplib2
    jsonschema
    pbr
    pymysql
    python-memcached
    python-swiftclient
    pythonRelaxDepsHook
    retrying
    stestr
    ;

in
python3Packages.buildPythonPackage (rec {
  pname = "glance";
  version = "29.0.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
    pythonRelaxDepsHook
  ];

  pythonRelaxDeps = [ "defusedxml" ];

  propagatedBuildInputs = [
    castellan
    cursive
    defusedxml
    glance-store
    httplib2
    jsonschema
    keystoneauth1
    keystonemiddleware
    os-brick
    os-win
    oslo-db
    oslo-i18n
    oslo-limit
    oslo-log
    oslo-messaging
    oslo-middleware
    oslo-policy
    oslo-reports
    oslo-upgradecheck
    osprofiler
    pymysql
    python-memcached
    retrying
    taskflow
    wsme
  ];

  nativeCheckInputs = [
    qemu
    stestr
  ];

  checkInputs = [
    python-cinderclient
    python-swiftclient
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-gI6+t3MnSiD3adVMDedWlRnk1wyGyVnGHCM3ByLYIrk=";
  };
})
