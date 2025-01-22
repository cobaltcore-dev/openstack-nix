{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    kazoo
    six
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "zake";
  version = "0.2.2";
  format = "wheel";

  propagatedBuildInputs = [
    kazoo
    six
  ];

  src = fetchPypi {
    inherit pname version format;
    python = "py2.py3";
    sha256 = "sha256-h7pXMtSVxKyGNzPc8UkmyGxgQR3Zw2qIb+EVmvv0/0g=";
  };
}
