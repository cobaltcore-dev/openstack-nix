{
  fetchPypi,
  python3Packages,
}:
python3Packages.buildPythonPackage rec {
  pname = "flake8_logging_format";
  version = "2024.24.12";
  format = "wheel";

  src = fetchPypi {
    inherit pname version format;
    python = "py3";
    dist = "py3";
    sha256 = "sha256-fZPCEHNUsQoFsaDYzNOpv7eTruEIAHdlEUyVinVB1nQ=";
  };
}
