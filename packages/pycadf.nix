{
  fetchPypi,
  oslo-config,
  oslo-serialization,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    fixtures
    flake8-import-order
    hacking
    pbr
    python-subunit
    pytz
    stestr
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "pycadf";
  version = "4.0.0";

  nativeBuildInputs = [
    pbr
    stestr
  ];

  propagatedBuildInputs = [
    pytz
    oslo-config
    oslo-serialization
  ];

  checkInputs = [
    coverage
    fixtures
    flake8-import-order
    hacking
    python-subunit
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-KM/Lek9gDGVnKdXA9F0OGksv7CcTLhsDAKlQaeEe/3k=";
  };
}
