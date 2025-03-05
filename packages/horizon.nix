{
  fetchPypi,
  python3Packages,
  xvfb-run,
  django-debreach,
  django-pyscss,
  enmerkar,
  futurist,
  gettext,
  keystoneauth1,
  oslo-concurrency,
  oslo-config,
  oslo-i18n,
  oslo-policy,
  oslo-serialization,
  oslo-upgradecheck,
  oslo-utils,
  osprofiler,
  python-cinderclient,
  python-glanceclient,
  python-keystoneclient,
  python-neutronclient,
  python-novaclient,
  python-swiftclient,
  xstatic-angular,
  xstatic-angular-bootstrap,
  xstatic-angular-fileupload,
  xstatic-angular-gettext,
  xstatic-angular-lrdragndrop,
  xstatic-angular-schema-form,
  xstatic-bootstrap-datepicker,
  xstatic-bootstrap-scss,
  xstatic-bootswatch,
  xstatic-jsencrypt,
  xstatic-d3,
  xstatic-font-awesome,
  xstatic-hogan,
  xstatic-jasmine,
  xstatic-jquery-migrate,
  xstatic-jquery-quicksearch,
  xstatic-jquery-tablesorter,
  xstatic-mdi,
  xstatic-objectpath,
  xstatic-rickshaw,
  xstatic-roboto-fontface,
  xstatic-smart-table,
  xstatic-spin,
  xstatic-term-js,
  xstatic-tv4,
}:
let
  inherit (python3Packages)
    babel
    coverage
    django
    django-compressor
    freezegun
    hacking
    iso8601
    libsass
    netaddr
    nodeenv
    pbr
    pycodestyle
    pymemcache
    pyscss
    pytest
    pytest-django
    pytest-html
    pyyaml
    requests
    selenium
    semantic-version
    testscenarios
    testtools
    tzdata
    xstatic
    xstatic-jquery
    xstatic-jquery-ui
    xvfbwrapper
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "horizon";
  version = "25.1.0";

  nativeBuildInputs = [
    pbr
    gettext
    enmerkar
  ];

  propagatedBuildInputs = [
    babel
    django
    django-compressor
    django-debreach
    django-pyscss
    futurist
    iso8601
    keystoneauth1
    libsass
    netaddr
    oslo-concurrency
    oslo-config
    oslo-i18n
    oslo-policy
    oslo-serialization
    oslo-upgradecheck
    oslo-utils
    osprofiler
    pymemcache
    pyscss
    python-cinderclient
    python-glanceclient
    python-keystoneclient
    python-neutronclient
    python-novaclient
    python-swiftclient
    pyyaml
    requests
    semantic-version
    tzdata
    xstatic
    xstatic-angular
    xstatic-angular-bootstrap
    xstatic-angular-fileupload
    xstatic-angular-gettext
    xstatic-angular-lrdragndrop
    xstatic-angular-schema-form
    xstatic-bootstrap-datepicker
    xstatic-bootstrap-scss
    xstatic-bootswatch
    xstatic-d3
    xstatic-font-awesome
    xstatic-hogan
    xstatic-jasmine
    xstatic-jquery
    xstatic-jquery-migrate
    xstatic-jquery-quicksearch
    xstatic-jquery-tablesorter
    xstatic-jquery-ui
    xstatic-jsencrypt
    xstatic-mdi
    xstatic-objectpath
    xstatic-rickshaw
    xstatic-roboto-fontface
    xstatic-smart-table
    xstatic-spin
    xstatic-term-js
    xstatic-tv4
  ];

  preBuild = ''
    python ./manage.py compilemessages
    python ./manage.py collectstatic -c --noinput
    python ./manage.py compress --force
  '';

  nativeCheckInputs = [
    pytest
    xvfb-run
  ];

  checkInputs = [
    coverage
    freezegun
    hacking
    nodeenv
    pycodestyle
    pytest-django
    pytest-html
    selenium
    testscenarios
    testtools
    xvfbwrapper
  ];

  postInstall = ''
    cp -r static $out/static-compressed
  '';
  # Tox is needed as test framework. Tox requires pip install inside the virtual env. Thus we test manually
  checkPhase = "
    ./tools/unit_tests.sh . horizon
    ./tools/unit_tests.sh . openstack_auth
  ";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-w+NOvS9kFlXJMgU8V7NRO92t2jE1UaE5A5CItyHy/Dc=";
  };
}
