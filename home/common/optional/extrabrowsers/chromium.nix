{
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--no-default-browser-check"
      "--restore-last-session"
      "--disable-features=WaylandWpColorManagerV1" # workaround for https://github.com/hyprwm/Hyprland/pull/11877 until the commit gets added to a new hyrpland release
    ];
  };
}
