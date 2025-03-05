{
  fetchPypi,
  oslo-log,
  oslo-i18n,
  oslo-concurrency,
  oslo-config,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    cffi
    eventlet
    fixtures
    greenlet
    msgpack
    python-dateutil
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.privsep";
  version = "3.5.0";

  propagatedBuildInputs = [
    cffi
    eventlet
    greenlet
    msgpack
    oslo-log
    oslo-i18n
    oslo-config
    oslo-concurrency
    oslo-utils
    python-dateutil
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    fixtures
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-tC5Is/9guOpKrMTepEYVU1Lv5sGMuKXmUY81NksBflc=";
  };
}
