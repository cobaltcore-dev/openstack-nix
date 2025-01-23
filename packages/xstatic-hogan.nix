{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Hogan";
  version = "2.0.0.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-J6khlj5HCrutoVsthdGYgzeVqurV/XMzm8KIPP3bVhk=";
  };
}
