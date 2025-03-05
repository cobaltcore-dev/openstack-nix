{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-JQuery.quicksearch";
  version = "2.0.3.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-84dg/pO1BPKFXvJem/kd9lyKZgFnQWXkaF+yF7thb9E=";
  };
}
