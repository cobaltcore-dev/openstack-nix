{
  fetchPypi,
  python-keystoneclient,
  keystoneauth1,
  openstacksdk,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    hacking
    pbr
    requests
    setuptools
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "python-swiftclient";
  version = "4.6.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
    setuptools
    requests
  ];

  propagagedBuildInputs = [
    requests
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    hacking
    keystoneauth1
    openstacksdk
    python-keystoneclient
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-1NGFQEE4k/wWrYd5HXQPgj92NDXoIS5o61PWDaJjgjM=";
  };
}
