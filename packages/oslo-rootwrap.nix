{
  bash,
  coreutils,
  dnsmasq,
  fetchPypi,
  lib,
  oslotest,
  python3Packages,
  writeScript,
}:
let
  inherit (python3Packages)
    eventlet
    fixtures
    stestr
    testtools
    ;

  testExcludes = [
    "test_ChainingRegExpFilter_match"
    "test_ChainingRegExpFilter_multiple"
    "test_KillFilter"
    "test_ReadFileFilter"
    "test_exec_dirs_search"
    "test_match_filter_recurses_exec_command_filter_matches"
    "test_run_with_later_install_cmd"
  ];

  testExcludeFile = writeScript "testExcludes" (lib.concatStringsSep "\n" testExcludes);
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.rootwrap";
  version = "7.4.0";

  postPatch = ''
    substituteInPlace ./oslo_rootwrap/tests/test_functional.py --replace-fail "/bin/cat" "${coreutils}/bin/cat"
    substituteInPlace ./oslo_rootwrap/tests/test_functional.py --replace-fail "/bin/echo" "${coreutils}/bin/echo"
    substituteInPlace ./oslo_rootwrap/tests/test_functional.py --replace-fail "/bin/sh" "${bash}/bin/sh"
    substituteInPlace ./oslo_rootwrap/tests/test_rootwrap.py --replace-fail "/bin/cat" "${coreutils}/bin/cat"
    substituteInPlace ./oslo_rootwrap/tests/test_rootwrap.py --replace-fail "/bin/ls" "${coreutils}/bin/echo"
    substituteInPlace ./oslo_rootwrap/tests/test_rootwrap.py --replace-fail "/usr/bin/dnsmasq" "${dnsmasq}/bin/dnsmasq"
  '';

  nativeCheckInputs = [
    coreutils
    stestr
  ];

  checkInputs = [
    eventlet
    fixtures
    oslotest
    testtools
  ];

  checkPhase = ''
    stestr run --exclude-list ${testExcludeFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-RFD+eZykocXZ4daIddqJHQ5PjxTwiqJgrUMQSzOiv9g=";
  };
}
