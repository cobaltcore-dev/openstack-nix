{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    pbr
    setuptools
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "oslo.i18n";
  version = "6.5.0";
  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];
  nativeBuildInputs = [
    pbr
    setuptools
  ];

  # We explicitly disable testing to avoid circular dependencies with oslo-config
  doCheck = false;

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-k5O8rpLq3F93ETLRxqsjmxmJb/bYheOvwhqfqk3pJNM=";
  };
}
