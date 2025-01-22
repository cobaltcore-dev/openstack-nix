{
  fetchPypi,
  oslo-concurrency,
  oslo-config,
  oslo-serialization,
  oslo-utils,
  pre-commit,
  python3Packages,
}:
let
  inherit (python3Packages)
    bandit
    coverage
    ddt
    docutils
    flake8-import-order
    hacking
    netaddr
    opentelemetry-exporter-otlp
    opentelemetry-sdk
    prettytable
    pymongo
    redis
    requests
    stestr
    testtools
    webob
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "osprofiler";
  version = "4.2.0";

  propagatedBuildInputs = [
    netaddr
    oslo-concurrency
    oslo-config
    oslo-serialization
    oslo-utils
    prettytable
    requests
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  pythonRelaxDeps = [
    "opentracing-2.4.0"
  ];

  checkInputs = [
    bandit
    coverage
    ddt
    docutils
    flake8-import-order
    hacking
    #jaeger-client
    opentelemetry-exporter-otlp
    opentelemetry-sdk
    pre-commit
    pymongo
    redis
    testtools
  ];

  checkPhase = ''
    # we can not execute the jaeger test, because they can not run under python >=3.7
    rm osprofiler/tests/unit/drivers/test_jaeger.py
    # elasticsearch is not present in nixos
    rm osprofiler/tests/unit/drivers/test_elasticsearch.py
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-bdHEviZFqPJBIQVdpbtGFojcr8fmtNS6vA7xumaQJ4E=";
  };
}
