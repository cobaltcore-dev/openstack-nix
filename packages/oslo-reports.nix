{
  fetchPypi,
  oslo-config,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    greenlet
    jinja2
    pbr
    psutil
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.reports";
  version = "3.5.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    jinja2
    oslo-config
    oslo-i18n
    oslo-serialization
    oslo-utils
    psutil
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    greenlet
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ypiItr4tfdX1f6oBsVsCiCJ0PWMooE51z6mzJ7JvpmY=";
  };
}
