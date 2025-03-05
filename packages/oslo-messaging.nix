{
  fetchPypi,
  futurist,
  oslo-config,
  oslo-context,
  oslo-log,
  oslo-metrics,
  oslo-middleware,
  oslo-serialization,
  oslo-service,
  oslo-utils,
  oslotest,
  pifpaf,
  python3Packages,
}:
let
  inherit (python3Packages)
    amqp
    cachetools
    confluent-kafka
    coverage
    debtcollector
    eventlet
    fixtures
    greenlet
    kombu
    packaging
    pbr
    pyyaml
    stestr
    stevedore
    testscenarios
    testtools
    webob
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.messaging";
  version = "15.0.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    amqp
    cachetools
    debtcollector
    futurist
    kombu
    oslo-config
    oslo-context
    oslo-log
    oslo-metrics
    oslo-middleware
    oslo-serialization
    oslo-service
    oslo-utils
    pyyaml
    stevedore
    webob
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    confluent-kafka
    coverage
    eventlet
    fixtures
    greenlet
    oslotest
    packaging
    pifpaf
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-dgNbvVFtrYAcRg/63qd0OG2ur69TrsPc9kgjMiny0nE=";
  };
}
