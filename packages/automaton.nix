{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    pbr
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "automaton";
  version = "3.2.0";

  nativeBuildInputs = [
    pbr
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-BHZwiG6bwxbjkVwjsJLN5QHUnK4NN6k6xt3jS1BEssw=";
  };
}
