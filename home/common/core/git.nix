# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  osConfig,
  secrets,
  lib,
  ...
}:
let
  ghCredential = "!${lib.getExe pkgs.gh} auth git-credential";
in
{
  # All users get git no matterwhat but additional settings may be added by eg: development.nix
  home.packages = [
    pkgs.delta # git diff tool
    pkgs.git-lfs
  ];

  introdus.color-conventional-commits = {
    enable = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      user = {
        name = osConfig.hostSpec.userFullName;
        email = secrets.email.user;
        signingkey = secrets.git.signingKey;
      };

      core = {
        pager = "delta";
        safecrlf = true;
        eol = "lf";
        whitespace = "trailing-space,indent-with-non-tab,-tab-in-indent";
        fileMode = false;
        symlinks = true;
        autocrlf = "input";
      };

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

      alias = {
        edit = "!$EDITOR $(git status --porcelain | awk '{print $2}')";
        co = "checkout";
        ci = "commit";
        st = "status";
        br = "branch";
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
        type = "cat-file -t";
        dump = "cat-file -p";
      };

      color = {
        ui = "auto";
        branch = true;
        diff = true;
        interactive = true;
        status = true;
      };

      pull.rebase = true;
      help.autocorrect = 1;
      gc.autoDetach = false;
      apply.whitespace = "nowarn";
      tag.forceSignAnnotated = true;
      gpg.program = "gpg2";
      commit.gpgsign = true;

      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      credential = {
        helper = "";
        "https://github.com".helper = [
          ""
          ghCredential
        ];
        "https://gist.github.com".helper = [
          ""
          ghCredential
        ];
      };
    };
  };

  home.sessionVariables.GIT_EDITOR = osConfig.hostSpec.defaultEditor;

  programs.zsh.shellAliases = {
    # Copy the last commit id from a branch
    glc = ''f() { git log --oneline $@ | head -1 | awk "{print \$1}" | wl-copy }; git rev-parse --is-inside-work-tree >/dev/null && f && echo "Copied commit: $(wl-paste)"'';
    glcf = ''f() { glo $@ | fzf --ansi --preview "git show --color=always {1}" | sed 's/\x1b\[[0-9;]*m//g' | awk "{print \$1}" | wl-copy }; git rev-parse --is-inside-work-tree >/dev/null && f && echo "Copied commit: $(wl-paste)"'';
  };

}
