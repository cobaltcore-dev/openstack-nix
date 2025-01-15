{
  fetchPypi,
  oslo-i18n,
  python3Packages,
}:
let
  inherit (python3Packages)
    debtcollector
    netaddr
    pbr
    pyyaml
    requests
    rfc3986
    stevedore
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.config";
  version = "9.7.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    debtcollector
    netaddr
    oslo-i18n
    pyyaml
    requests
    rfc3986
    stevedore
  ];

  # we cannot enable the check phase, because we get a circular dependency on oslo.log
  doCheck = false;

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-s3Hr8/mmPpK4HVxyuE0vlvQFU1MmmcaOHFzYyp7KCIs=";
  };
}
