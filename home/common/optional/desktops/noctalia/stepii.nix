{
  bar.default = {
    position = "top";
    margin_edge = 4;
    margin_ends = 4;
    padding = 2;
    font_scale = 1.25;
    background_opacity = 0.2;
    border = "outline";
    border_width = 8;
    radius = 12;
    concave_edge_corners = false;
    capsule = true;
    capsule_opacity = 1.0;
    widget_spacing = 6;

    start = [
      "launcher"
      "spacer-left"
      "workspaces"
      "sysmon-cpu"
    ];
    center = [
      "privacy"
      "active_window"
      "screen_recorder"
    ];
    end = [
      "notifications"
      "tray"
      "volume"
      "network"
      "bluetooth"
      "battery"
      "brightness"
      "clock"
      "spacer-right"
      "control-center"
    ];
  };

  widget = {
    launcher.glyph = "rocket";

    spacer-left = {
      type = "spacer";
      length = 30;
    };
    spacer-right = {
      type = "spacer";
      length = 30;
    };

    workspaces = {
      style = "regular";
      show_labels = true;
      label_source = "name";
      labels_only_when_occupied = false;
      pill_scale = 1.0;
    };

    sysmon-cpu = {
      type = "sysmon";
      stat = "cpu_usage";
      visualization = "none";
      show_value = true;
    };

    active_window = {
      max_length = 500;
      display = "icon_and_text";
      title_scroll = "on_hover";
    };

    clock.format = "{:%H:%M  %y.%m.%d}";

    screen_recorder.type = "noctalia/screen_recorder:recorder";
  };

  plugins = {
    enabled = [ "noctalia/screen_recorder" ];
    auto_update = "all";
  };

  plugin_settings."noctalia/screen_recorder" = {
    copy_to_clipboard = true;
    hide_inactive = true;
  };

  theme = {
    mode = "dark";
    shell_mode = "dark";
    source = "custom";
    custom_palette = "stylix";
  };
}
