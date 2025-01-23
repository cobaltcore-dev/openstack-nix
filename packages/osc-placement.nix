{
  fetchPypi,
  keystoneauth1,
  osc-lib,
  oslo-utils,
  oslo-serialization,
  oslotest,
  python3Packages,
}:
let
  inherit (python3Packages)
    pbr
    stestr
    ;
in
python3Packages.buildPythonPackage (rec {
  pname = "osc-placement";
  version = "4.5.0";
  pyproject = true;

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    keystoneauth1
    osc-lib
    oslo-serialization
    oslo-utils
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    oslotest
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-gx1nQZ0e//um9XzSKKn9sWknVkfkqVN+snVmJla3zY8=";
  };
})
