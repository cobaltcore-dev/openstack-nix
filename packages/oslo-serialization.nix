{
  fetchPypi,
  oslo-i18n,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    msgpack
    netaddr
    pbr
    stestr
    tzdata
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.serialization";
  version = "5.6.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    msgpack
    oslo-utils
    tzdata
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    netaddr
    oslo-i18n
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-TH1OEtqFPMTwS5EjBBE06Iboyf9Xq1fBli061Kh7f3w=";
  };
}
