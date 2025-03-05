{
  fetchPypi,
  lib,
  oslo-concurrency,
  oslo-config,
  oslo-i18n,
  oslo-log,
  oslo-privsep,
  oslo-serialization,
  oslo-utils,
  oslo-versionedobjects,
  oslotest,
  ovs,
  ovsdbapp,
  python3Packages,
  writeScript,
}:
let
  inherit (python3Packages)
    coverage
    debtcollector
    netifaces
    pbr
    pyroute2
    stevedore
    stestr
    testscenarios
    ;

  testExcludes = [
    "TestIpCommand"
    "test__set_mtu_request"
    "test_create_ovs_vif_port"
    "test_create_ovs_vif_port_with_default_qos"
    "test_create_patch_port_pair"
    "test_delete_ovs_vif_port"
    "test_delete_qos_if_exists"
    "test_ensure_ovs_bridge"
    "test_get_qos"
    "test_plug_unplug_ovs_port_with_qos"
    "test_plug_unplug_ovs_vhostuser_trunk"
    "test_port_exists"
    "test_set_mtu"
  ];
  excludeListFile = writeScript "test_excludes" (lib.concatStringsSep "\n" testExcludes);
in
python3Packages.buildPythonPackage rec {
  pname = "os_vif";
  version = "3.5.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    debtcollector
    netifaces
    ovsdbapp
    oslo-concurrency
    oslo-config
    oslo-i18n
    oslo-log
    oslo-privsep
    oslo-serialization
    oslo-utils
    oslo-versionedobjects
    pyroute2
    stevedore
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    oslotest
    ovs
    testscenarios
  ];

  installCheckPhase = ''
    substituteInPlace os_vif/internal/__init__.py --replace-fail "raise exception.ExternalImport()" "pass"
    stestr run --exclude-list ${excludeListFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-14o08f5grIc3IDWs3ySRFmKrEH/SyxWsNAjM4i9yUqo=";
  };
}
