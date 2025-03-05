{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-mdi";
  version = "1.6.50.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-vhAFr3pZOws6NJqtsF5BYOpliUJIpHskbGZYNF4vEME=";
  };
}
