{
  fetchPypi,
  memcached,
  oslo-config,
  oslo-i18n,
  oslo-log,
  oslo-utils,
  oslotest,
  pifpaf,
  python-binary-memcached,
  python3Packages,
}:
let
  inherit (python3Packages)
    dogpile-cache
    etcd3
    pymemcache
    pymongo
    python-dateutil
    python-memcached
    redis
    stestr
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "oslo.cache";
  version = "3.9.0";

  propagatedBuildInputs = [
    dogpile-cache
    oslo-config
    oslo-i18n
    oslo-log
    oslo-utils
    python-dateutil
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    etcd3
    memcached
    oslotest
    pifpaf
    pymemcache
    pymongo
    python-binary-memcached
    python-memcached
    redis
  ];

  checkPhase = ''
    stestr run
  '';

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-wvsufWTMFmIroWUoiw97J/eK8ClM8z6IPHzc7FFdQIs=";
  };
}
