{
  R,
  dotnet-sdk,
  fetchFromGitHub,
  git,
  nodejs,
  perl,
  python3Packages,
  ruby,
  swift,
}:
let
  inherit (python3Packages)
    cfgv
    coverage
    distlib
    identify
    mccabe
    nodeenv
    pytest
    pytest-env
    pyyaml
    re-assert
    virtualenv
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "pre_commit";
  version = "4.0.1";

  nativeBuildInputs = [
    R
    dotnet-sdk
    git
    nodejs
    perl
    pytest
    pytest-env
    ruby
    swift
  ];

  propagatedBuildInputs = [
    cfgv
    coverage
    distlib
    identify
    nodeenv
    pyyaml
    re-assert
    virtualenv
  ];

  checkInputs = [
    mccabe
  ];

  postPatch = ''
    mkdir -p .git/hooks
  '';

  disabledTests = [
    "conda"
    "coursier"
    "dart"
    "docker"
    "docker_image"
    "dotnet"
    "golang"
    "haskell"
    "init_templatedir"
    "install_uninstall"
    "lua"
    "main"
    "node"
    "perl"
    "repository"
    "ruby"
    "rust"
    "swift"
    "test_health_check_after_downgrade"
    "test_health_check_healthy"
    "test_health_check_without_version"
    "test_lots_of_files"
    "test_r_hook"
    "test_r_inline"
  ];

  # We need to fetch the sources directly from GitHub here, because the
  # packaging and testing requires the .git folder to determine the correct tool
  # version.
  src = fetchFromGitHub {
    owner = "pre-commit";
    repo = "pre-commit";
    rev = "v4.0.1";
    sha256 = "sha256-qMNnzAxJOS7mabHmGYZ/VkDrpaZbqTJyETSCxq/OrGQ=";
    leaveDotGit = true;
  };
}
