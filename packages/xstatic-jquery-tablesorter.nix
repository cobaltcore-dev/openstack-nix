{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-JQuery.TableSorter";
  version = "2.14.5.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-vdhHygzeQBT9IRNPmeWame9IgYXHRegmRpEdL53j12I=";
  };
}
