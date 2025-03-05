{
  castellan,
  cursive,
  fetchPypi,
  keystoneauth1,
  keystonemiddleware,
  lib,
  os-brick,
  os-win,
  oslo-db,
  oslo-i18n,
  oslo-limit,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-reports,
  oslo-upgradecheck,
  oslo-vmware,
  oslotest,
  osprofiler,
  python-cinderclient,
  python3Packages,
  taskflow,
  writeScript,
}:
let
  inherit (python3Packages)
    boto3
    ddt
    defusedxml
    httplib2
    jsonschema
    pbr
    python-swiftclient
    requests-mock
    retrying
    stestr
    ;

  excludeList = [
    "test_add_check_metadata_list_with_valid_mountpoint_locations"
  ];

  excludeListFile = writeScript "testExcludes" (lib.concatStringsSep "\n" excludeList);
in
python3Packages.buildPythonPackage (rec {
  pname = "glance_store";
  version = "4.8.1";
  pyproject = true;

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    castellan
    cursive
    ddt
    defusedxml
    httplib2
    jsonschema
    keystoneauth1
    keystonemiddleware
    os-win
    oslo-db
    oslo-i18n
    oslo-limit
    oslo-log
    oslo-messaging
    oslo-middleware
    oslo-reports
    oslo-upgradecheck
    osprofiler
    retrying
    taskflow
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    boto3
    os-brick
    oslo-vmware
    oslotest
    python-cinderclient
    python-swiftclient
    requests-mock
  ];

  checkPhase = ''
    stestr run --exclude-list ${excludeListFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-nkLWMCzcytNyI+rZoHRBWh1LnA7+gCcrN7YoZFb0dzc=";
  };
})
