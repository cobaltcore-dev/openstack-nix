{ pkgs, pre-commit-hooks-run }:
{
  pre-commit-check = pre-commit-hooks-run {
    src = pkgs.nix-gitignore.gitignoreSource [ ] ../.;
    tools = pkgs;
    hooks = {
      nixpkgs-fmt.enable = true;
      deadnix.enable = true;
      typos.enable = true;
    };
  };
}
