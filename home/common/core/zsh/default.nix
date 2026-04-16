{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
{
  #
  # ========= Programs integrated to zsh via option or alias =========
  #

  #Adding these packages here because the are tied to zsh
  home.packages = [
    pkgs.rmtrash # temporarily cache deleted files for recovery
    pkgs.fzf # fuzzy finder used by initExtra.zsh
  ];
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd" # replace cd with z and zi (via cdi)
    ];
  };

  #
  # ========= Actual zsh options =========
  #
  programs.zsh = {
    enable = true;

    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    autosuggestion.enable = true;
    history.size = 10000;
    history.share = true;

    # NOTE: zsh module will load *.plugin.zsh files by default if they are located in the src=<folder>, so
    # supply the full folder path to the plugin in src=. To find the correct path, atm you must check the
    # plugins derivation until PR XXXX (file issue) is fixed
    plugins = import ./plugins.nix {
      inherit pkgs;
    };

    initContent = lib.mkAfter (lib.readFile ./zshrc);
    oh-my-zsh = {
      enable = true;
      # Standard OMZ plugins pre-installed to $ZSH/plugins/
      # Custom OMZ plugins are added to $ZSH_CUSTOM/plugins/
      # Enabling too many plugins will slowdown shell startup
      plugins = [
        "git"
        # NOTE: disabling sudo plugin because it is super annoying with esc/ctrl mapped to same key
        #"sudo" # press Esc twice to get the previous command prefixed with sudo https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sudo
      ];
      extraConfig = ''
        # Display red dots whilst waiting for completion.
                COMPLETION_WAITING_DOTS="true"
      '';
    };
    sessionVariables = {
      EDITOR = "nvim";
    };

    shellAliases = import ./aliases.nix { inherit osConfig; };
  };
}
