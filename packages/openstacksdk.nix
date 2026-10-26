{
  keystoneauth1,
  python3Packages,
}:
let
  inherit (python3Packages)
    platformdirs
    cryptography
    decorator
    dogpile-cache
    iso8601
    jmespath
    jsonpatch
    openstackdocstheme
    os-service-types
    pbr
    psutil
    pythonOlder
    pyyaml
    requestsexceptions
    setuptools
    sphinxHook
    typing-extensions
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "openstacksdk";
  version = "4.4.0";
  pyproject = true;

  disabled = pythonOlder "3.9";

  outputs = [
    "out"
    "man"
  ];

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-FXQ3Vj1k8/b+7BeW+9hVLVYnczJGF3jE2+dtGCj9MeA=";
  };

  postPatch = ''
    # Disable rsvgconverter not needed to build manpage
    substituteInPlace doc/source/conf.py \
      --replace-fail "'sphinxcontrib.rsvgconverter'," "#'sphinxcontrib.rsvgconverter',"
  '';

  nativeBuildInputs = [
    openstackdocstheme
    sphinxHook
  ];

  sphinxBuilders = [ "man" ];

  build-system = [ setuptools ];

  dependencies = [
    platformdirs
    cryptography
    decorator
    dogpile-cache
    iso8601
    jmespath
    jsonpatch
    keystoneauth1
    os-service-types
    pbr
    psutil
    requestsexceptions
    pyyaml
    typing-extensions
  ];

  # Checks moved to 'passthru.tests' to workaround slowness
  doCheck = false;

  #passthru.tests = {
  #  tests = callPackage ./tests.nix { };
  #};

  pythonImportsCheck = [ "openstack" ];
}
