{ fetchPypi, python3Packages }:
let
  inherit (python3Packages)
    cairosvg
    sphinx
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "sphinxcontrib_svg2pdfconverter";
  version = "1.2.3";

  nativeBuildInputs = [
    sphinx
  ];

  propagatedBuildInputs = [
    cairosvg
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-+11Re2NMVilSIATFntzk2QUNiYIkCMq0UsfVL+WumCQ=";
  };
}
