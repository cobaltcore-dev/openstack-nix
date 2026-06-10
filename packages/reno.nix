{
  fetchFromGitHub,
  git,
  gnupg,
  python3Packages,
}:
let
  inherit (python3Packages)
    coverage
    dulwich
    openstackdocstheme
    packaging
    pbr
    subunit
    pyyaml
    stestr
    testscenarios
    testtools
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "reno";
  version = "4.1.0";

  nativeBuildInputs = [
    git
    gnupg
    pbr
  ];

  propagatedBuildInputs = [
    dulwich
    packaging
    pyyaml
  ];

  nativeCheckInputs = [
    stestr
  ];

  checkInputs = [
    coverage
    openstackdocstheme
    subunit
    testscenarios
    testtools
  ];

  checkPhase = ''
    stestr run
  '';

  # The tests use the .git directory and git itself, thus we need to check out the repo.
  src = fetchFromGitHub {
    owner = "openstack";
    repo = "reno";
    rev = "${version}";
    sha256 = "sha256-zB/iAR0YV3QaQVshCva24OgvRokT+lDeTXGeHi6XkUA=";
    leaveDotGit = true;
  };
}
