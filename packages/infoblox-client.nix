{
  fetchPypi,
  python3Packages,
  oslo-log,
  oslo-serialization,
}:
let
  inherit (python3Packages)
    stestr
    requests
    urllib3
    six
    ;
in
python3Packages.buildPythonPackage (rec {
  pname = "infoblox-client";
  version = "0.6.2";
  pyproject = true;
  build-system = [
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
  ];

  propagatedBuildInputs = [
    oslo-log
    oslo-serialization
    requests
    urllib3
    six
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
  ];

  # checkPhase = ''
  #   stestr run
  # '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-0hkgof6LLAwp2rYOl8rgLTSFYeQauik7Bi4rzhmszVE=";
  };
})
