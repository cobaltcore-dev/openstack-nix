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
    subunit
    stestr
    testrepository
    testresources
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "cursive";
  version = "0.2.3";

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  postPatch = ''
    sed -i '/ec\.SECT571K1()/d; /ec\.SECT409K1()/d; /ec\.SECT571R1()/d; /ec\.SECT409R1()/d' cursive/signature_utils.py
  '';

  doCheck = false;

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
    subunit
    testrepository
    testresources
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  pythonImportsCheck = [
    "cursive.signature_utils"
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-9DX2zb5qUX8FTBEFw25DbXhoEk8bIn0xD+gJ2RiowQw=";
  };

}
