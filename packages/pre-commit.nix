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
    setuptools
    virtualenv
    ;
in
python3Packages.buildPythonPackage rec {
  pname = "pre_commit";
  version = "4.0.1";

  pyproject = true;
  build-system = [ setuptools ];

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
    "test_healthy_default_creator"
    "test_healthy_venv_creator"
    "test_language_versioned_python_hook"
    "test_lots_of_files"
    "test_r_hook"
    "test_r_inline"
    "test_python_hook_weird_setup_cfg"
    "test_simple_python_hook"
    "test_simple_python_hook_default_version"
    "test_unhealthy_old_virtualenv"
    "test_unhealthy_python_goes_missing"
    "test_unhealthy_system_version_changes"
    "test_unhealthy_then_replaced"
    "test_unhealthy_unexpected_pyvenv"
    "test_unhealthy_with_version_change"
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
