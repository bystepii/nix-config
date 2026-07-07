{ pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;

    # themeFile = "tokyo_night_storm";

    font = {
      name = lib.mkForce "HackNerdFont-Regular";
      size = lib.mkForce 13;
    };

    settings = {
      enable_audio_bell = false;
      disable_ligatures = "never";
      url_color = "#61afef";
      url_style = "curly";
      detect_urls = true;
      cursor_shape = "beam";
      cursor_beam_thickness = 1.8;
      mouse_hide_wait = 3000;
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;
      # background_opacity = lib.mkForce "0.9";
      tab_bar_style = "powerline";
      inactive_tab_background = "#e06c75";
      active_tab_background = "#98c379";
      inactive_tab_foreground = "#000000";
      tab_bar_margin_color = "black";
      shell = "zsh";
    };

    keybindings = {
      "ctrl+shift+n" = "next_layout";
      "ctrl+shift+h" = "neighboring_window left";
      "ctrl+shift+j" = "neighboring_window down";
      "ctrl+shift+k" = "neighboring_window up";
      "ctrl+shift+l" = "neighboring_window right";
      "ctrl+shift+left" = "neighboring_window left";
      "ctrl+shift+right" = "neighboring_window right";
      "ctrl+shift+up" = "neighboring_window up";
      "ctrl+shift+down" = "neighboring_window down";
      "ctrl+shift+s" = "show_scrollback";
      "ctrl+alt+shift+h" = "previous_tab";
      "ctrl+alt+shift+l" = "next_tab";
      "ctrl+alt+shift+left" = "previous_tab";
      "ctrl+alt+shift+right" = "next_tab";
      "ctrl+shift+z" = "toggle_layout stack";
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+t" = "new_tab_with_cwd";
      "f1" = "copy_to_buffer a";
      "f2" = "paste_from_buffer a";
      "f3" = "copy_to_buffer b";
      "f4" = "paste_from_buffer b";
    };

    shellIntegration = {
      enableZshIntegration = true;
      mode = "no-sudo";
    };

    extraConfig = ''
      remote_dir /tmp/kitty-ssh-kitten
      window_padding_width 20
      scrollback_pager nvim --cmd 'set eventignore=FileType' +'nnoremap q ZQ' +'call nvim_open_term(0, {})' +'set nomodified nolist' +'$'
    '';
  };
}
