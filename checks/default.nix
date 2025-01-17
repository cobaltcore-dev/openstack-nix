{ pkgs, pre-commit-hooks-run }:
{
  pre-commit-check = pre-commit-hooks-run {
    src = pkgs.nix-gitignore.gitignoreSource [ ] ../.;
    tools = pkgs;
    hooks = {
      nixfmt-rfc-style.enable = true;
      deadnix.enable = true;
      typos.enable = true;
    };
  };
}
