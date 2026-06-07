#Note: ctrl+r to cycle filter modes
{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  sopsFolder = (lib.toString inputs.nix-secrets) + "/sops";
in
{
  # FIXME(atuin): Add the background sync service
  # https://forum.atuin.sh/t/getting-the-daemon-working-on-nixos/334
  programs.atuin = {
    enable = true;

    enableBashIntegration = false;
    enableZshIntegration = false; # NOTE: false because of zsh-vi-mode, see below
    enableFishIntegration = false;

    settings = {
      auto_sync = true;
      #FIXME(atuin): move to private server
      sync_address = "https://api.atuin.sh";
      sync_frequency = "30m";
      update_check = false;
      filter_mode = "global";
      invert = true;
      enter_accept = true;
      #TODO(atuin): disable when comfortable
      show_help = true;
      prefers_reduced_motion = true;

      style = "compact";
      inline_height = 10;
      search_mode = "fuzzy";
      filter_mode_shell_up_key_binding = "session";

      # This came from https://github.com/nifoc/dotfiles/blob/ce5f9e935db1524d008f97e04c50cfdb41317766/home/programs/atuin.nix#L2
      history_filter = [
        "^base64decode"
        "^instagram-dl"
        "^mp4concat"
      ];
    };

    # We use down to trigger, and use up to quickly edit the last entry only
    flags = [ "--disable-up-arrow" ];
  };
  sops.secrets."keys/atuin" = {
    path = "${config.home.homeDirectory}/.local/share/atuin/key";
    sopsFile = "${sopsFolder}/shared.yaml";
  };

  programs.zsh.initContent =
    let
      flagsstr = lib.escapeShellArgs config.programs.atuin.flags;
    in
    ''
      # bind down key for atuin, specifically because we use invert
      bindkey "$key[Down]" atuin-up-search

      # work around zsh-vi-mode bug
      # https://github.com/atuinsh/atuin/issues/1826
      if [[ $options[zle] = on ]]; then
        function atuin_init() {
          eval "$(${pkgs.atuin}/bin/atuin init zsh ${flagsstr})"
        }
        zvm_after_init_commands+=(atuin_init)
      fi
    '';

}
