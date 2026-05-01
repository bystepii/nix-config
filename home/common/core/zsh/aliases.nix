{
  #osConfig,
  ...
}:
let
  devDirectory = "$HOME/src";
  devNix = "${devDirectory}/nix";
in
{
  # Overrides those provided by OMZ libs, plugins, and themes.
  # For a full list of active aliases, run `alias`.

  whichreal = ''function _whichreal(){ (alias "$1" >/dev/null 2>&1 && (alias "$1" | sed "s/.*=.\(.*\).../\1/" | xargs which)) || which "$1"; }; _whichreal'';

  #-------------Bat related------------
  # cat = "bat --paging=never";        # using user's alias
  # diff = "batdiff";                   # conflicts with user's setup
  # less = "bat --style=plain";         # using user's alias
  rg = "rg -M300";

  #------------Navigation------------
  rst = "reset";
  doc = "cd $HOME/doc";
  edu = "cd $HOME/edu";
  wiki = "cd $HOME/sync/obsidian-vault-01/wiki";
  # l = "eza -lah";                     # conflicts with lsd
  # la = "eza -lah";                    # conflicts with lsd
  ldt = "eza -TD"; # list directory tree
  # ll = "eza -lh";                     # conflicts with lsd
  # ls = "eza";                         # conflicts with lsd
  # lsa = "eza -lah";                   # conflicts with lsd
  # tree = "eza -T";                    # conflicts with lsd
  ".h" = "cd ~"; # Because I find pressing ~ tedious"
  cdr = "cd-gitroot";
  ".r" = "cd-gitroot";
  cdpr = "..; cd-gitroot";
  "..r" = "..; cd-gitroot";

  #------------compression------------
  unzip = "7z x";

  #------------ src navigation------------
  src = "cd ${devDirectory}";
  cab = "cd ${devDirectory}/abbot-wiki";
  cuc = "cd ${devDirectory}/unmoved-centre";
  ## nix
  cna = "cd ${devNix}/nix-assets";
  cnc = "cd ${devNix}/nix-config";
  cnh = "cd ${devNix}/nixos-hardware";
  cni = "cd ${devNix}/introdus";
  cnit = "cd ${devNix}/introdus/ta";
  cnp = "cd ${devNix}/nixpkgs";
  cns = "cd ${devNix}/nix-secrets";
  cnv = "cd ${devNix}/neovim";

  #-----------Nix commands----------------
  nfc = "nix flake check";
  ne = "nix instantiate --eval";
  nb = "nix build";
  ns = "nix shell";
  nrepl = ''
    nix repl --option experimental-features "flakes pipe-operators" \
    --expr 'rec { pkgs = import <nixpkgs>{}; lib = pkgs.lib; }'
  '';

  # prevent accidental killing of single characters
  pkill = "pkill -x";

  #-------------direnv---------------
  da = "direnv allow";
  dr = "direnv reload";

  #-------------justfiles---------------
  jr = "just rebuild";
  jrt = "just rebuild-trace";
  jl = "just --list";
  jup = "just update";
  jug = "just upgrade";

  #-------------Neovim---------------
  e = "nvim";
  vi = "nvim";
  vim = "nvim";

  #-------------journalctl---------------
  jc = "journalctl";
  jcu = "journalctl --user";

  #-------------SSH---------------
  ssh = "TERM=xterm ssh";
  # pinghosts = "nmap -sP ${osConfig.hostSpec.networking.subnets.grove.cidr}";
  # scanhostson10022 = "sudo nmap -sS ${osConfig.hostSpec.networking.subnets.grove.cidr} -p ${toString osConfig.hostSpec.networking.ports.tcp.ssh}";

  #-------------rmtrash---------------
  # Path to real rm and rmdir in coreutils. This is so we can not use rmtrash for big files
  rrm = "/run/current-system/sw/bin/rm";
  rrmdir = "/run/current-system/sw/bin/rmdir";
  # rm = "rmtrash";                     # conflicts with trash
  # rmdir = "rmdirtrash";               # conflicts with trash

  #-------------Git Goodness-------------
  # git aliases moved to introdus

  # ========= User's Ubuntu aliases =========
  # Navigation with lsd
  l = "lsd --group-dirs=first";
  la = "lsd -a --group-dirs=first";
  ll = "lsd -lh --group-dirs=first";
  lla = "lsd -lha --group-dirs=first";
  ls = "lsd --group-dirs=first";

  # Bat aliases
  cat = "bat --paging=never";

  # Trash
  rm = "trash ";

  # Sudo with trailing space for alias expansion
  sudo = "sudo ";

  # Git aliases
  gs = "git status ";
  ga = "git add ";
  gb = "git branch ";
  gc = "git commit";
  gd = "git diff";
  gt = "git checkout ";
  gk = "gitk --all&";
  gx = "gitx --all";
  got = "git ";
  get = "git ";

  # GitHub Copilot aliases
  copilot = "gh copilot";
  gcs = "gh copilot suggest";
  gce = "gh copilot explain";

  # Kitty icat
  icat = "kitty +kitten icat";

  # RustScan
  rustscan = "docker run -it --rm --name rustscan rustscan/rustscan";

  # Commented-out PATH exports for future nix migration
  # export PATH="$HOME/go/bin:$PATH"                # golang - TODO: use nixpkgs#go
  # export PATH="$HOME/.cargo/bin:$PATH"            # rust/cargo - TODO: use nixpkgs#cargo
  # export PATH="$HOME/.local/bin:$PATH"            # local bins
  # export PATH="$HOME/bin:$PATH"                   # personal bins
  # export PATH="$PATH:/home/stepii/.local/share/JetBrains/Toolbox/scripts"  # JetBrains
  # export PATH="$HOME/.pixi/bin:$PATH"             # pixi - using nixpkgs#pixi instead
  # export PATH="$HOME/perl5/bin:$PATH"             # perl local::lib
  # export PATH="/usr/local/cuda/bin:$PATH"         # CUDA - TODO: use nixpkgs#cuda
  # export PATH="/home/stepii/texlive/2024/bin/x86_64-linux/:$PATH"  # TeX Live - TODO: use nixpkgs#texlive
  # export ANDROID_HOME=$HOME/Android/Sdk           # Android SDK - TODO: use nixpkgs#androidsdk
  # export PATH=$PATH:$ANDROID_HOME/emulator        # Android emulator
  # export PATH=$PATH:$ANDROID_HOME/platform-tools  # Android platform-tools
  # export NVM_DIR="$HOME/.nvm"                     # Node Version Manager - TODO: use nixpkgs#nodePackages
  # export SDKMAN_DIR="$HOME/.sdkman"               # SDKMAN - TODO: use nixpkgs alternatives
  # eval "$(pixi completion --shell zsh)"           # handled by installing pixi package
}
