{
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
    subunit
    sphinx
    testrepository
    testscenarios
    testtools
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "jsonpath-rw-ext";
  version = "1.2.2";

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    jsonpath-rw
  ];

  checkInputs = [
    coverage
    hacking
    oslotest
    subunit
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
