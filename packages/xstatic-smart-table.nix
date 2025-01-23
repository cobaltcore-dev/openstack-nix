{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-smart-table";
  version = "1.4.13.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-8vpe03wpUyU955xhw0b6bDxPOHMSldIkBVLBQpjbawo=";
  };
}
