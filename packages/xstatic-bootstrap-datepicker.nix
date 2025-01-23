{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Bootstrap-Datepicker";
  version = "1.4.0.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-3zOt2fXnhfqISsSxgmAa9qrJ4e7vfP5i27ywZU0PLW4=";
  };
}
