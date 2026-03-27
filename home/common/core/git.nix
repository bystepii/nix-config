# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  osConfig,
  ...
}:
{
  # All users get git no matterwhat but additional settings may be added by eg: development.nix
  home.packages = [
    pkgs.delta # git diff tool
  ];

  introdus.color-conventional-commits = {
    enable = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      core.pager = "delta";
      delta = {
        enable = true;
        features = [
          "side-by-side"
          "line-numbers"
          "hyperlinks"
          "line-numbers"
          "commit-decoration"
        ];
      };
      alias.edit = "!$EDITOR $(git status --porcelain | awk '{print $2}')";
    };
  };

  home.sessionVariables.GIT_EDITOR = osConfig.hostSpec.defaultEditor;

  programs.zsh.shellAliases = {
    # Copy the last commit id from a branch
    glc = ''f() { git log --oneline $@ | head -1 | awk "{print \$1}" | wl-copy }; git rev-parse --is-inside-work-tree >/dev/null && f && echo "Copied commit: $(wl-paste)"'';
    glcf = ''f() { glo $@ | fzf --ansi --preview "git show --color=always {1}" | sed 's/\x1b\[[0-9;]*m//g' | awk "{print \$1}" | wl-copy }; git rev-parse --is-inside-work-tree >/dev/null && f && echo "Copied commit: $(wl-paste)"'';
  };

}
