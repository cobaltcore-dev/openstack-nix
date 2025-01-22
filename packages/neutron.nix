{
  doc8,
  fetchPypi,
  futurist,
  iproute2,
  keystoneauth1,
  keystonemiddleware,
  lib,
  neutron-lib,
  openstacksdk,
  os-ken,
  os-resource-classes,
  os-vif,
  oslo-cache,
  oslo-concurrency,
  oslo-config,
  oslo-context,
  oslo-db,
  oslo-i18n,
  oslo-log,
  oslo-messaging,
  oslo-middleware,
  oslo-policy,
  oslo-privsep,
  oslo-reports,
  oslo-rootwrap,
  oslo-serialization,
  oslo-service,
  oslo-upgradecheck,
  oslo-utils,
  oslo-versionedobjects,
  oslotest,
  osprofiler,
  ovs,
  ovsdbapp,
  python-designateclient,
  python-neutronclient,
  python-novaclient,
  python3Packages,
  tooz,
  writeScript,
}:
let
  inherit (python3Packages)
    coverage
    ddt
    debtcollector
    decorator
    eventlet
    fixtures
    hacking
    httplib2
    jinja2
    netaddr
    paste
    pastedeploy
    pbr
    pecan
    psutil
    pymysql
    python-memcached
    pyopenssl
    pyroute2
    python-subunit
    requests
    routes
    sqlalchemy
    stestr
    tenacity
    testresources
    testscenarios
    testtools
    webob
    webtest
    ;

  excludeList = [
    "test__dhcp_ready_ports_loop"
    "test_create_agent"
    "test_create_subnet_bad_pools"
    "test_dhcp_ready_ports_loop_with_limit_ports_per_call"
    "test_disable_check_process_id_env_var"
    "test_enable_check_process_id_env_var"
    "test_flavors"
    "test_network_create_end"
    "test_network_delete_end"
    "test_network_update_end_admin_state_down"
    "test_network_update_end_admin_state_up"
    "test_port_create_duplicate_ip_on_dhcp_agents_same_network"
    "test_port_create_end"
    "test_port_create_end_no_resync_if_same_port_already_in_cache"
    "test_port_delete_end"
    "test_port_delete_end_agents_port"
    "test_port_delete_end_no_network_id"
    "test_port_delete_end_unknown_port"
    "test_port_delete_network_already_deleted"
    "test_port_update_change_ip_on_dhcp_agents_port"
    "test_port_update_change_ip_on_dhcp_agents_port_cache_miss"
    "test_port_update_change_ip_on_port"
    "test_port_update_change_subnet_on_dhcp_agents_port"
    "test_port_update_end"
    "test_port_update_on_dhcp_agents_port_no_ip_change"
    "test_remote_sg_removed"
    "test_sg_removed"
    "test_subnet_create_end"
    "test_subnet_delete_end_no_network_id"
    "test_subnet_update_dhcp"
    "test_subnet_update_end"
    "test_subnet_update_end_delete_payload"
    "test_subnet_update_end_restart"
    "test_sync"
    "test_sync_state_disabled_net"
    "test_sync_state_for_all_networks_plugin_error"
    "test_sync_state_for_one_network_plugin_error"
    "test_sync_state_initial"
    "test_sync_state_same"
    "test_sync_state_waitall"
    "test_sync_teardown_namespace"
    "test_sync_teardown_namespace_does_not_crash_on_error"
    "test_update_subnet_allocation_pools_invalid_returns_400"
  ];

  excludeListFile = writeScript "testExcludes" (lib.concatStringsSep "\n" excludeList);

in
python3Packages.buildPythonPackage rec {
  pname = "neutron";
  version = "25.1.0";

  nativeBuildInputs = [
    pbr
  ];

  propagatedBuildInputs = [
    debtcollector
    decorator
    eventlet
    futurist
    httplib2
    jinja2
    keystoneauth1
    keystonemiddleware
    netaddr
    neutron-lib
    openstacksdk
    os-ken
    os-resource-classes
    os-vif
    oslo-cache
    oslo-concurrency
    oslo-config
    oslo-context
    oslo-db
    oslo-i18n
    oslo-log
    oslo-messaging
    oslo-middleware
    oslo-policy
    oslo-privsep
    oslo-reports
    oslo-rootwrap
    oslo-serialization
    oslo-service
    oslo-upgradecheck
    oslo-utils
    oslo-versionedobjects
    osprofiler
    ovs
    ovsdbapp
    paste
    pastedeploy
    pecan
    psutil
    pymysql
    pyopenssl
    pyroute2
    python-designateclient
    python-memcached
    python-neutronclient
    python-novaclient
    requests
    routes
    sqlalchemy
    tenacity
    tooz
    webob
  ];

  nativeCheckInputs = [
    iproute2
    stestr
  ];

  checkInputs = [
    coverage
    ddt
    doc8
    fixtures
    hacking
    oslotest
    pymysql
    python-subunit
    testresources
    testscenarios
    testtools
    webtest
  ];

  checkPhase = ''
    stestr run --exclude-list ${excludeListFile}
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-dOqLLiSTqjldioKUzY4HgbCKNyyDX1bu2huoBs297zE=";
  };
}
