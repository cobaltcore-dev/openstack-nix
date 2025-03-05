{
  fetchPypi,
  oslo-config,
  oslo-i18n,
  oslo-policy,
  oslo-serialization,
  oslo-utils,
  oslotest,
  pre-commit,
  python3Packages,
}:
let
  inherit (python3Packages)
    hacking
    prettytable
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.upgradecheck";
  version = "2.4.0";

  propagatedBuildInputs = [
    oslo-config
    oslo-i18n
    oslo-policy
    oslo-utils
    prettytable
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    hacking
    oslo-serialization
    oslotest
    pre-commit
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-q3kZHnSyrobDuKj0mrSfwOSYns3krU701NXiTpVreZM=";
  };
}
