{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    setuptools
    pip
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "rcssmin";
  version = "1.1.2";

  pyproject = true;

  nativeBuildInputs = [
    setuptools
    pip
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-vHXrdb1tNFwMUf2A/Eh93W+f1AndeGGz/pje6FAY4ek=";
  };
}
