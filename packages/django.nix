{
  fetchPypi,
  python3Packages,
}:
let
  inherit (python3Packages)
    asgiref
    pip
    setuptools
    sqlparse
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "django";
  version = "4.2.30";

  pyproject = true;

  nativeBuildInputs = [
    pip
    setuptools
  ];

  propagatedBuildInputs = [
    asgiref
    sqlparse
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Trx6Q044Gdts9LOZ+1s/U2MQow6EhvCLZohoQL6Es3w=";
  };
}
