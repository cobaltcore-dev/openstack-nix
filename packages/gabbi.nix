{
  fetchPypi,
  jsonpath-rw-ext,
  python3Packages,
}:
let
  inherit (python3Packages)
    certifi
    colorama
    coverage
    hacking
    pbr
    pytest
    pytest-cov
    pyyaml
    requests-mock
    sphinx
    stestr
    urllib3
    wsgi-intercept
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "gabbi";
  version = "3.0.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    pytest
    pyyaml
    urllib3
    certifi
    jsonpath-rw-ext
    wsgi-intercept
    colorama
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    requests-mock
    coverage
    pytest-cov
    hacking
    sphinx
  ];

  # We skip the below tests, because they need internet
  checkPhase = ''
    stestr run --exclude-regex ".*test_live|test_intercept.*"
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-zP9PtbyssmKzvyzPF52axUdVsVmtcMSYRSBp34dZ8Pw=";
  };
}
