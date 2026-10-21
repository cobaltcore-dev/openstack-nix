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
  version = "30.0.0";
  # Single-store tests must register their options independently of test order.
  patches = [
    ./patches/glance-single-store-test-options.patch
  ];

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

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

  # The schema-image.json is required for glance configuration but currently not
  # exported by the python package.
  postFixup = ''
    cp etc/schema-image.json $out/etc/glance/
  '';

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-4p35NHTioaNBY+4VnnIzGUHMCzCwAJIlk/lUDAHGjlo=";
  };
})
