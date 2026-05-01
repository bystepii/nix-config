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
    pkgs.fzf # fuzzy finder used by initExtra.zsh
    pkgs.lsd # ls replacement (user prefers over eza)
    pkgs.trash-cli # trash command for rm alias
    pkgs.zsh-powerlevel10k # prompt theme
    pkgs.pixi # package manager
    pkgs.awscli2 # AWS CLI
    pkgs.xclip # clipboard for X11
    pkgs.wl-clipboard # clipboard for Wayland
    pkgs.kitty # terminal emulator (for icat alias)
  ];

  # Deploy p10k config
  home.file.".p10k.zsh".source = ./p10k.zsh;

  # Link p10k into OMZ custom themes directory so OMZ can load it natively
  home.file.".oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme".source =
    pkgs.zsh-powerlevel10k + "/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd" # replace cd with z and zi (via cdi)
    ];
  };

  # Import custom functions
  imports = [ ./zsh-functions.nix ];

  #
  # ========= Actual zsh options =========
  #
  programs.zsh = {
    enable = true;

    dotDir = "${config.home.homeDirectory}/.config/zsh";
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

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Point OMZ custom dir to home-manager-managed path before OMZ initializes
        export ZSH_CUSTOM="${config.home.homeDirectory}/.oh-my-zsh/custom"
      '')
      (lib.mkAfter (lib.readFile ./zsh-init.zsh))
    ];

    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      # Standard OMZ plugins pre-installed to $ZSH/plugins/
      # Custom OMZ plugins are added to $ZSH_CUSTOM/plugins/
      # Enabling too many plugins will slowdown shell startup
      plugins = [
        "git"
        # NOTE: disabling sudo plugin because it is super annoying with esc/ctrl mapped to same key
        #"sudo" # press Esc twice to get the previous command prefixed with sudo
        "docker"
        "docker-compose"
        "kubectl"
        "helm"
        "terraform"
        "aws"
        "ansible"
        "python"
        "pip"
        "node"
        "npm"
        "yarn"
        "golang"
        "rust"
        "extract"
        "history"
        "command-not-found"
        "vscode"
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

  # Enable fzf zsh integration (replaces manual ~/.fzf.zsh source)
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Enable dircolors (replaces eval "$(dircolors -b)")
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };
}
