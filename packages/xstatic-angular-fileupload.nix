{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Angular-FileUpload";
  version = "12.2.13.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-+PQxrH+zewGgEIEfuK6X8ODLEcu9BOScWGfqf3T62lY=";
  };
}
