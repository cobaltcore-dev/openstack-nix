{
  etcd3gw,
  fetchPypi,
  futurist,
  lib,
  oslo-serialization,
  oslo-utils,
  pifpaf,
  python3Packages,
  writeScript,
  zake,
}:
let
  inherit (python3Packages)
    coverage
    ddt
    fasteners
    fixtures
    msgpack
    pymemcache
    pymysql
    stestr
    stevedore
    sysv_ipc
    tenacity
    testtools
    voluptuous
    ;

  testExcludes = [
    "test_lock_context_manager_acquire_argument"
    "test_lock_context_manager_acquire_no_argument"
    "test_parsing_blocking_settings"
    "test_parsing_timeout_settings"
  ];

  testExcludeFile = writeScript "testExcludes" (lib.concatStringsSep "\n" testExcludes);
in
python3Packages.buildPythonPackage rec {
  pname = "tooz";
  version = "6.3.0";

  propagatedBuildInputs = [
    fasteners
    futurist
    msgpack
    oslo-serialization
    oslo-utils
    stevedore
    tenacity
    voluptuous
  ];

  checkInputs = [
    coverage
    ddt
    etcd3gw
    fixtures
    pifpaf
    pymemcache
    pymysql
    sysv_ipc
    testtools
    zake
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkPhase = ''
    TOOZ_TEST_URL=file:///tmp stestr run --exclude-list ${testExcludeFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-lTA/XW+5bWTEq0uANo6MkZgER4S0/wkDAdpDVa3SWck=";
  };
}
