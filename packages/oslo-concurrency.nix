{
  bash,
  coreutils,
  fetchPypi,
  oslo-config,
  oslo-i18n,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    eventlet
    fixtures
    pbr
    fasteners
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.concurrency";
  version = "6.0.0";

  postPatch = ''
    substituteInPlace oslo_concurrency/tests/unit/test_processutils.py --replace-fail "/usr/bin/env" "${coreutils}/bin/env"
    substituteInPlace oslo_concurrency/tests/unit/test_processutils.py --replace-fail "/bin/bash" "${bash}/bin/bash"
    substituteInPlace oslo_concurrency/tests/unit/test_processutils.py --replace-fail "/bin/true" "${coreutils}/bin/true"
  '';

  nativeBuildInputs = [
    coreutils
    pbr
  ];

  propagatedBuildInputs = [
    fasteners
    oslo-config
    oslo-i18n
    oslo-utils
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    eventlet
    fixtures
    oslotest
  ];

  checkPhase = ''
    stestr run --exclude-regex ".*lock_with.*"
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-tS8CtORvXydLkfuOG/xcv5pBjfzUqDvggDRUlePSboo=";
  };
}
