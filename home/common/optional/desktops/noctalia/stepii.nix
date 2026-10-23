{
  inputs,
  osConfig,
  ...
}:
{
  bar.default = {
    position = "top";
    margin_edge = 4;
    margin_ends = 4;
    padding = 2;
    font_scale = 1.25;
    background_opacity = 0.2;
    border = "outline";
    border_width = 0;
    radius = 12;
    concave_edge_corners = false;
    capsule = true;
    capsule_opacity = 1.0;
    widget_spacing = 6;

    start = [
      "launcher"
      "spacer-left"
      "workspaces"
      "group:sysmon"
    ];
    center = [
      "privacy"
      "active_window"
      "timer"
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

    capsule_group = [
      {
        id = "sysmon";
        members = [
          "sysmon-cpu"
          "sysmon-temp"
          "sysmon-ram"
          "sysmon-net-rx"
          "sysmon-net-tx"
        ];
        fill = "surface_variant";
        padding = 6.0;
        opacity = 1.0;
      }
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
      max_label_chars = 10;
      occupied_color = "tertiary";
      empty_color = "tertiary";
      font_weight = 600;
      pill_scale = 1.0;
    };

    sysmon-cpu = {
      type = "sysmon";
      stat = "cpu_usage";
      visualization = "none";
      show_value = true;
      color = "secondary";
    };
    sysmon-temp = {
      type = "sysmon";
      stat = "cpu_temp";
      visualization = "none";
      show_value = true;
      color = "secondary";
    };
    sysmon-ram = {
      type = "sysmon";
      stat = "ram_used";
      visualization = "none";
      show_value = true;
      color = "secondary";
    };
    sysmon-net-rx = {
      type = "sysmon";
      stat = "net_rx";
      visualization = "none";
      show_value = true;
      color = "secondary";
    };
    sysmon-net-tx = {
      type = "sysmon";
      stat = "net_tx";
      visualization = "none";
      show_value = true;
      color = "secondary";
    };

    active_window = {
      max_length = 500;
      display = "icon_and_text";
      title_scroll = "on_hover";
      color = "secondary";
    };

    clock = {
      format = "{:%H:%M  %y.%m.%d.%a}";
      color = "secondary";
    };

    battery = {
      display_mode = "graphic";
      show_label = false;
    };

    network.show_label = false;
    brightness.show_label = false;

    tray = {
      drawer = true;
      hide_passive = false;
    };

    privacy = {
      hide_inactive = false;
      active_color = "error";
      inactive_color = "on_surface_variant";
      icon_spacing = 4;
    };

    timer.type = "noctalia/timer:bar";
    screen_recorder.type = "noctalia/screen_recorder:recorder";

    volume.actions.middle = "exec pwvucontrol || pavucontrol";
  };

  plugins = {
    enabled = [
      "noctalia/timer"
      "noctalia/screen_recorder"
    ];
    auto_update = "none";
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
    sync_color_scheme = false;
    pure_black_dark = false;
    templates = {
      enable_builtin_templates = false;
      enable_community_templates = false;
    };
  };

  wallpaper = {
    enabled = true;
    fill_mode = "crop";
    transition = [
      "fade"
      "disc"
      "stripes"
      "wipe"
      "pixel"
      "honeycomb"
    ];
    transition_duration = 1500;
    edge_smoothness = 0.05;
    transition_on_startup = false;
    default.path = toString osConfig.hostSpec.wallpaper;
  };

  shell = {
    font_family = "FiraMono Nerd Font";
    avatar_path = "${inputs.nix-assets}/images/avatars/emergentmind_avatar_200k.png";
    time_format = "{:%H:%M}";
    lang = "";
    telemetry_enabled = false;
    card_borders = false;
    show_location = true;
    clipboard_auto_paste = "off";
    clipboard_enabled = true;

    animation = {
      enabled = true;
      speed = 1.0;
    };

    shadow.direction = "down_right";
    screen_corners.enabled = false;

    panel = {
      transparency_mode = "soft";
      launcher_placement = "floating";
      launcher_position = "center";
      clipboard_placement = "attached";
    };

    launcher = {
      layout = "full";
      app_grid = false;
      sort_by_usage = true;
      show_session_button = true;
      show_settings_button = true;
      categories = true;
      pinned = [ ];
      auto_paste = "off";
    };

    session = {
      show_shortcuts = true;
      grid = false;
      actions = [
        {
          action = "lock";
          shortcut = "1";
          countdown_seconds = 0.0;
        }
        {
          action = "suspend";
          shortcut = "2";
          countdown_seconds = 0.0;
        }
        {
          action = "command";
          command = "systemctl hibernate";
          shortcut = "3";
          countdown_seconds = 0.0;
        }
        {
          action = "reboot";
          shortcut = "4";
          countdown_seconds = 0.0;
        }
        {
          action = "logout";
          shortcut = "5";
          countdown_seconds = 0.0;
        }
        {
          action = "shutdown";
          shortcut = "6";
          countdown_seconds = 0.0;
        }
        {
          action = "reboot_uefi";
          shortcut = "7";
          countdown_seconds = 0.0;
        }
      ];
    };
  };

  keybinds = {
    down = [
      "Down"
      "Ctrl+J"
    ];
    validate = [
      "Return"
      "Enter"
    ];
    cancel = [ "Esc" ];
    left = [
      "Left"
      "Ctrl+H"
    ];
    delete = [ "Del" ];
    right = [
      "Right"
      "Ctrl+L"
    ];
    up = [
      "Up"
      "Ctrl+K"
    ];
  };

  lockscreen = {
    blur_intensity = 0.25;
    tint_intensity = 0.6;
    blurred_desktop = true;
    fingerprint = true;
    lock_before_suspend = true;
  };

  notification = {
    background_opacity = 0.8;
    layer = "overlay";
    position = "top_right";
  };

  osd = {
    position = "top_right";
    position_vertical = "top_right";
    hide_delay_ms = 2000;
    background_opacity = 0.8;
  };

  control_center = {
    show_shortcut_labels = true;
    shortcuts = [
      { type = "wifi"; }
      { type = "bluetooth"; }
      { type = "wallpaper"; }
      { type = "notification"; }
      { type = "power_profile"; }
    ];
    calendar = {
      show_events_card = true;
      show_week_numbers = false;
    };
  };

  location = {
    address = "Calgary";
    auto_locate = false;
  };

  weather = {
    enabled = true;
    effects = true;
    unit = "metric";
  };

  calendar.enabled = true;

  system.monitor = {
    cpu_usage_activity_threshold = 80.0;
    cpu_usage_critical_threshold = 90.0;
    cpu_temp_activity_threshold = 80.0;
    cpu_temp_critical_threshold = 90.0;
    gpu_temp_activity_threshold = 80.0;
    gpu_temp_critical_threshold = 90.0;
    gpu_usage_activity_threshold = 80.0;
    gpu_usage_critical_threshold = 90.0;
    gpu_vram_activity_threshold = 80.0;
    gpu_vram_critical_threshold = 90.0;
    ram_pct_activity_threshold = 80.0;
    ram_pct_critical_threshold = 90.0;
    swap_pct_activity_threshold = 80.0;
    swap_pct_critical_threshold = 90.0;
    disk_used_pct_activity_threshold = 80.0;
    disk_used_pct_critical_threshold = 90.0;
  };

  battery.warning_threshold = 20;

  nightlight = {
    enabled = false;
    force = false;
    temperature_day = 6500;
    temperature_night = 4000;
  };

  desktop_widgets.enabled = false;
  dock.enabled = false;
}
