{
  fetchPypi,
  futurist,
  pifpaf,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    oslotest
    pbr
    pytest
    python-subunit
    requests
    testrepository
    testscenarios
    testtools
    urllib3
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "etcd3gw";
  version = "2.4.2";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    futurist
    requests
  ];

  checkInputs = [
    coverage
    oslotest
    pifpaf
    pytest
    python-subunit
    testrepository
    testscenarios
    testtools
    urllib3
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-bG6eQrgQ7pqUVd00LemJ8fq2N6lNqk/DTKyySKVEc/o=";
  };
}
