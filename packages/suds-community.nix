{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    pytest
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "suds_community";
  version = "1.2.0";

  checkInputs = [
    pytest
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-qzsk3Juga15lmOKl000qfQbHnmE9gc7cAoR1v707uQw=";
  };
}
