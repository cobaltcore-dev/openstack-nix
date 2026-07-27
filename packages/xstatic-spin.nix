{ fetchPypi, python3Packages }:
python3Packages.buildPythonPackage rec {
  pname = "XStatic-Spin";
  version = "1.2.5.3";

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-BuiJzzMY8IznTviItF2fHgkBe7jm1RmimcEKnmtUJkI=";
  };
}
