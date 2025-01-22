{
  fetchPypi,
  openvswitch,
  python3Packages,
}:
let
  inherit (python3Packages)
    netaddr
    packaging
    pyftpdlib
    pyparsing
    pytest
    scapy
    setuptools
    sortedcontainers
    tftpy
    ;

in
python3Packages.buildPythonPackage rec {
  pname = "ovs";
  version = "3.4.1";

  nativeBuildInputs = [
    openvswitch
    setuptools
  ];

  # we need to remove windows files due to errors in the tests
  postPatch = ''
    rm ovs/winutils.py
    rm ovs/fcntl_win.py
  '';

  propagatedBuildInputs = [
    sortedcontainers
  ];

  checkInputs = [
    netaddr
    packaging
    pyftpdlib
    pyparsing
    pytest
    scapy
    tftpy
  ];

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-bBdrG9Cc8LqI815ua5c6Tfyp2k02/bAmY/AzSaTa3b4=";
  };
}
