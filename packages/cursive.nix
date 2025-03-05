{
  castellan,
  fetchPypi,
  oslo-i18n,
  oslo-log,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    cryptography
    hacking
    mock
    pbr
    python-subunit
    stestr
    testrepository
    testresources
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "cursive";
  version = "0.2.3";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    castellan
    cryptography
    oslo-i18n
    oslo-log
    oslo-serialization
    oslo-utils
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    hacking
    mock
    oslotest
    python-subunit
    testrepository
    testresources
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-9DX2zb5qUX8FTBEFw25DbXhoEk8bIn0xD+gJ2RiowQw=";
  };

}
