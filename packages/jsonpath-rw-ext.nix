{
  discover,
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    hacking
    jsonpath-rw
    oslotest
    pbr
    python-subunit
    sphinx
    testrepository
    testscenarios
    testtools
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "jsonpath-rw-ext";
  version = "1.2.2";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    jsonpath-rw
  ];

  checkInputs = [
    coverage
    discover
    hacking
    oslotest
    python-subunit
    sphinx
    testrepository
    testscenarios
    testtools
  ];

  src = fetchPypi {
    inherit pname version;

    sha256 = "sha256-qeROgDtth9E1sJ0eWvDbTUz5e6YnEagKpRyMchmAqZQ=";
  };
}
