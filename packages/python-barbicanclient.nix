{
  fetchPypi,
  keystoneauth1,
  oslo-config,
  oslo-i18n,
  oslo-serialization,
  oslo-utils,
  oslotest,
  python3Packages,
  sphinxcontrib-svg2pdfconverter,
}:
let
  inherit (python3Packages)
    cliff
    coverage
    fixtures
    hacking
    pbr
    python-openstackclient
    requests
    requests-mock
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-barbicanclient";
  version = "7.0.0";

  nativeBuildInputs = [
    pbr
    stestr
  ];

  propagatedBuildInputs = [
    cliff
    keystoneauth1
    oslo-i18n
    oslo-serialization
    oslo-utils
    requests
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    fixtures
    hacking
    oslo-config
    oslotest
    python-openstackclient
    requests-mock
    sphinxcontrib-svg2pdfconverter
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-MWrzinbWWkr5E1xwCn86RuKlqwSF6TlpaH9rYjFylcc=";
  };
}
