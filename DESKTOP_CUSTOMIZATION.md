# Desktop & UI Customization Guide

This guide covers customizing your graphical environment, display manager, compositor, desktop shell, and system-wide theming. It is a companion to the general [`CUSTOMIZATION.md`](./CUSTOMIZATION.md).

---

## 1. Desktop Architecture Overview

Your graphical session is built in layers, split between **system-level** (NixOS) and **home-level** (Home-Manager) configuration.

```
┌─────────────────────────────────────────────┐
│  Display Manager  (SilentSDDM)              │  ← System
│  └─ Session selector → launches compositor  │
├─────────────────────────────────────────────┤
│  Compositor       (Niri via UWSM)           │  ← System
│  └─ Window management, workspaces, binds    │
├─────────────────────────────────────────────┤
│  Desktop Shell    (Noctalia)                │  ← Home
│  └─ Bar, dock, launcher, notifications, OSD │
├─────────────────────────────────────────────┤
│  Monitor Profiles (Kanshi)                  │  ← Home
│  └─ Auto-layout outputs per host            │
├─────────────────────────────────────────────┤
│  Theming          (Stylix / Base16)         │  ← System + Home
│  └─ Colors, fonts, cursors, GTK/Qt          │
└─────────────────────────────────────────────┘
```

**System-level** (`hosts/nixos/<host>/default.nix`) enables the session infrastructure: Niri, SDDM, PipeWire audio, graphics drivers.

**Home-level** (`home/<user>/<host>.nix`) imports the user-facing desktop modules: Niri KDL config, Noctalia settings, Kanshi profiles.

**Per-host overrides** live in `hosts/nixos/<host>/niri/` (KDL fragments) and `hosts/nixos/<host>/monitors.nix` (display specs).

---

## 2. Host-Spec Desktop Flags

Set these in `hosts/nixos/<host>/host-spec.nix` to control desktop behavior globally.

| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `useWayland` | bool | `false` | Enables Wayland session variables and Wayland compositors. |
| `useX11` | bool | auto | Enables Xorg. Auto-true if `useWindowManager && !useWayland`. |
| `useWindowManager` | bool | `true` | Enables display manager, keyring, and WM packages. |
| `defaultDesktop` | str | `"niri"` | Session name passed to the display manager. |
| `isAutoStyled` | bool | `false` | **Enables Stylix** theming across the entire system. |
| `theme` | str | `"dracula"` | Base16 theme name (from `pkgs.base16-schemes`). |
| `wallpaper` | path | nix-assets | Default wallpaper path used by Stylix. |
| `hdr` | bool | `false` | HDR display support (affects SDDM DPI/scaling). |
| `scaling` | str | `"1"` | HiDPI scale factor (string for floating point). |
| `voiceCoding` | bool | `false` | **Forbidden with `useWayland`** (Talon does not support Wayland). |

### Assertions (enforced at build time)
- `voiceCoding && useWayland` → **build fails**.
- `primaryUsername` must exist in the `users` list.

---

## 3. System-Level Display Stack

These options go in your host's `default.nix`.

### Niri Compositor
```nix
introdus.niri.enable = true;
```
This module (`introdus/modules/nixos/niri.nix`) does the following:
- Installs `pkgs.unstable.niri`.
- Installs `xwayland-satellite` for X11 app compatibility.
- Enables `programs.uwsm` and registers Niri as a UWSM-managed compositor.

### Display Manager (SilentSDDM)
```nix
introdus.services.silent-sddm.enable = true;
```
This module (`introdus/modules/nixos/silent-sddm.nix`) does the following:
- Imports the `silentSDDM` flake input.
- Enables SDDM with a SilentSDDM theme.
- **Automatically enables X11** (`introdus.services.x11.enable = true`) because SDDM requires it for stability on some GPUs.
- Configures PAM to unlock `gnome-keyring` on login.

> **Note:** If you want SDDM to use a Wayland backend, set:
> ```nix
> services.displayManager.sddm.wayland.enable = lib.mkForce true;
> ```

### Audio & Graphics
```nix
introdus.services.audio.enable = true;   # PipeWire + ALSA + Pulse compat
hardware.graphics.enable = true;          # Required for any graphical session
```

### Complete Minimal Desktop Block
```nix
# In hosts/nixos/<host>/default.nix
introdus.niri.enable = true;
introdus.services.silent-sddm.enable = true;
services.displayManager.sddm.wayland.enable = lib.mkForce true; # optional
introdus.services.audio.enable = true;
hardware.graphics.enable = true;
```

---

## 4. Home-Manager Desktop Modules

Compose your desktop in `home/<user>/<host>.nix`:

```nix
{ lib, ... }:
{
  imports = map lib.custom.relativeToRoot (
    [
      "home/common/core"
      "home/<user>/common"
    ]
    ++ map (f: "home/common/optional/${f}") [
      "desktops/niri"           # Compositor config (KDL)
      "desktops/noctalia.nix"   # Desktop shell (bar, launcher, OSD)
      "desktops/services/kanshi.nix"  # Monitor profiles
    ]
  );
}
```

### Available Desktop Modules

| Module | What it does | Conflicts / Notes |
|--------|--------------|-------------------|
| `desktops/niri/` | Niri KDL config assembly | Needs `useWayland = true` |
| `desktops/gnome/` | GNOME dconf settings, extensions | Needs `hosts/common/optional/gnome.nix` |
| `desktops/noctalia.nix` | Noctalia desktop shell | Disables Waybar (`lib.mkForce false`) |
| `desktops/services/kanshi.nix` | Dynamic monitor profiles | Reads `osConfig.monitors` |

> **Important:** Do not import `desktops/noctalia.nix` and a Waybar config at the same time. Noctalia explicitly forces Waybar off.

---

## 5. Niri Configuration (KDL Assembly)

Niri is configured via a single `config.kdl` file. Your config assembles it declaratively from fragments.

### How the Assembly Works

`home/common/optional/desktops/niri/default.nix` builds the final config by concatenating files **in order**:

```nix
let
  hostPath = "hosts/nixos/${osConfig.hostSpec.hostName}/niri";
  finalConfig = lib.flatten [
    ./inputs.kdl                                    # 1. Input devices
    (map lib.custom.relativeToRoot [
      "${hostPath}/outputs.kdl"                     # 2. Per-host outputs
      "${hostPath}/workspaces.kdl"                  # 3. Per-host workspaces
      "${hostPath}/startup.kdl"                     # 4. Per-host startup apps
    ])
    ./binds.kdl                                     # 5. Keybindings
    ./rules.kdl                                     # 6. Window rules
    ./config.kdl                                    # 7. General config
  ]
  |> lib.concatMapStringsSep "\n" lib.readFile;
in
{
  home.file = {
    ".config/niri/config.kdl".text = finalConfig;
    ".config/niri/animations/" = {
      source = ./animations;
      recursive = true;
    };
  };
}
```

### File Purposes

| Fragment | Purpose |
|----------|---------|
| `inputs.kdl` | Keyboard layout, repeat rate, touchpad, mouse accel, power key handling. |
| `binds.kdl` | All keybindings (workspaces, window management, media keys, Noctalia IPC calls). |
| `rules.kdl` | Window rules (sizes, opacity, presets, app-specific behavior). |
| `config.kdl` | Startup commands, animations, overview settings, screenshots, CSD preference. |
| `animations/` | Animation preset files (`.kdlx` to avoid formatter mangling). |

### Per-Host Overrides

To customize Niri for a specific host, create files under:

```
hosts/nixos/<host>/niri/
├── outputs.kdl      # Monitor outputs, positions, resolutions
├── workspaces.kdl   # Workspace definitions, assignments
└── startup.kdl      # Host-specific startup commands
```

These files are **automatically included** if they exist. You do not need to edit `home/common/optional/desktops/niri/default.nix`.

#### Example: `hosts/nixos/onyx/niri/outputs.kdl`
```kdl
output "DP-5" {
    mode "2560x1440@165.000"
    position x=0 y=0
}
output "DP-6" {
    mode "2560x1440@165.000"
    position x=2560 y=0
}
```

#### Example: `hosts/nixos/onyx/niri/workspaces.kdl`
```kdl
workspace "1_dev" { output "DP-5" }
workspace "2_uci" { output "DP-5" }
workspace "9_com" { output "DP-6" }
```

#### Example: `hosts/nixos/onyx/niri/startup.kdl`
```kdl
spawn-at-startup "special-host-app"
```

### Adding New Fragment Files

If you want to add a new global fragment (e.g., `layouts.kdl`):

1. Create the file in `home/common/optional/desktops/niri/`.
2. Edit `home/common/optional/desktops/niri/default.nix` and add it to the `finalConfig` list.

```nix
finalConfig = lib.flatten [
  ./inputs.kdl
  (map lib.custom.relativeToRoot [ ... ])
  ./binds.kdl
  ./rules.kdl
  ./layouts.kdl   # <-- your new fragment
  ./config.kdl
]
```

### Animation Presets

Available presets in `home/common/optional/desktops/niri/animations/`:
- `honeycomb.kdlx`
- `glitch_01.kdlx`

Select one in `config.kdl`:
```kdl
include "animations/honeycomb.kdlx"
animations {
  slowdown 2.4
}
```

To add a custom animation, create a `.kdlx` file in the `animations/` directory and update the `include` line.

---

## 6. Noctalia-Shell Customization

Noctalia is your desktop shell: top bar, app launcher, control center, notifications, OSD, wallpaper manager, and session menu.

### Module Location
- **Home module:** `home/common/optional/desktops/noctalia.nix`
- **System timer:** `introdus/modules/home/auto/noctalia.nix` (snapshots settings hourly)

### Settings Structure

The Noctalia home module is a large attribute set under `programs.noctalia-shell.settings`. The main sections are:

| Section | What it controls |
|---------|------------------|
| `general` | Avatar, clock, lock screen, animations, keybinds, blur, shadows. |
| `appLauncher` | Launcher position, icon mode, clipboard, pinned apps, search options. |
| `bar` | Bar type, position, widgets (left/center/right), auto-hide, margins. |
| `dock` | Dock position, pinned apps, indicators, auto-hide. |
| `controlCenter` | Cards (audio, brightness, weather, shortcuts), position. |
| `notifications` | Location, duration, sounds, history. |
| `osd` | On-screen display for volume/brightness. |
| `wallpaper` | Directory, automation, transitions, solid color. |
| `audio` | MPRIS, volume feedback, visualizer. |
| `calendar` | Calendar cards, weather. |
| `sessionMenu` | Power options (lock, suspend, reboot, etc.), keybinds. |
| `colorSchemes` | Dark mode, generation method, wallpaper-based colors. |
| `ui` | Font scales, panel opacity, scrollbar, tooltip behavior. |
| `colors` | Manual color overrides (mapped from Stylix in this config). |

### Plugin System

Noctalia supports plugins from external sources:

```nix
programs.noctalia-shell.plugins = {
  sources = [
    {
      enabled = true;
      name = "Official Noctalia Plugins";
      url = "https://github.com/noctalia-dev/noctalia-plugins";
    }
  ];
  states = {
    privacy-indicator = { enabled = true; sourceUrl = url; };
    rss-feed = { enabled = true; sourceUrl = url; };
    timer = { enabled = true; sourceUrl = url; };
  };
  version = 2;
};
```

Plugin-specific settings go under `pluginSettings`:
```nix
programs.noctalia-shell.pluginSettings = {
  privacy-indicator = {
    activeColor = "error";
    hideInactive = true;
  };
};
```

### Common Tweaks

#### Bar Widgets
The bar is split into `left`, `center`, and `right` widget arrays:

```nix
programs.noctalia-shell.settings.bar.widgets = {
  left = [
    { id = "Spacer"; width = 30; }
    { id = "Workspace"; labelMode = "name"; showBadge = true; }
  ];
  center = [
    { id = "plugin:privacy-indicator"; }
    { id = "ActiveWindow"; showIcon = true; showText = true; }
  ];
  right = [
    { id = "NotificationHistory"; }
    { id = "Volume"; displayMode = "alwaysShow"; }
    { id = "Network"; displayMode = "onhover"; }
    { id = "Clock"; formatHorizontal = "HH:mm  yy.MM.dd.ddd"; }
  ];
};
```

Available widget IDs include: `Workspace`, `ActiveWindow`, `Clock`, `Volume`, `Network`, `Bluetooth`, `Battery`, `Tray`, `NotificationHistory`, `Spacer`, and `plugin:*` entries.

#### Launcher Pinned Apps
```nix
programs.noctalia-shell.settings.appLauncher.pinnedApps = [
  "firefox"
  "ghostty"
  "thunar"
];
```

#### Wallpaper Automation
```nix
programs.noctalia-shell.settings.wallpaper = {
  enabled = true;
  automationEnabled = true;
  directory = "/home/<user>/wallpapers";
  randomIntervalSec = 3600;
  transitionType = [ "fade" "disc" "stripes" ];
};
```

#### Session Menu Power Options
```nix
programs.noctalia-shell.settings.sessionMenu.powerOptions = [
  { action = "lock"; enabled = true; keybind = "1"; }
  { action = "suspend"; enabled = true; keybind = "2"; }
  { action = "reboot"; enabled = true; keybind = "3"; }
];
```

#### Colors (Stylix Integration)
Your config manually maps Stylix base16 colors into Noctalia:

```nix
programs.noctalia-shell.colors = {
  Surface = lib.mkForce "#${config.lib.stylix.colors.base00}";
  mOnSurface = lib.mkForce "#${config.lib.stylix.colors.base03}";
  mPrimary = lib.mkForce "#${config.lib.stylix.colors.base02}";
  mSecondary = lib.mkForce "#${config.lib.stylix.colors.base0F}";
  mError = lib.mkForce "#${config.lib.stylix.colors.base08}";
  # ... etc
};
```

If Stylix is disabled (`isAutoStyled = false`), these `config.lib.stylix.colors` references will fail. Either enable Stylix or replace them with hex strings.

### Settings Snapshot Timer
Because Noctalia stores runtime settings in `~/.config/noctalia/settings.json`, a systemd timer runs hourly to snapshot changes:

- **Timer:** `systemd.user.timers.noctalia-snapshot-settings`
- **Service:** `systemd.user.services.noctalia-snapshot-settings`
- **Backups:** `~/.cache/noctalia/backup/settings_YYYYMMDD_HHMMSS.json` (max 5 retained)

This lets you port runtime changes back into Nix later.

---

## 7. Monitor Configuration

Monitors are defined at the **system level** and consumed by both Kanshi (Home-Manager) and Niri (KDL).

### Spec File
Create or edit `hosts/nixos/<host>/monitors.nix`:

```nix
{ ... }:
{
  monitors = [
    {
      name = "DP-5";
      width = 2560;
      height = 1440;
      refreshRate = 165;
      primary = true;
      x = 0;
      y = 0;
      scale = 1.0;
    }
    {
      name = "DP-6";
      width = 2560;
      height = 1440;
      refreshRate = 165;
      x = 2560;
      y = 0;
      scale = 1.0;
      workspace = "9";
    }
  ];
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | str | Output name (from `wlr-randr` or `niri msg outputs`). |
| `width` | int | Horizontal resolution. |
| `height` | int | Vertical resolution. |
| `refreshRate` | int | Refresh rate in Hz. |
| `primary` | bool | Primary output (for scripts). |
| `x`, `y` | int | Position in the virtual desktop. |
| `scale` | float | HiDPI scale factor. |
| `workspace` | str | Default workspace for this output. |
| `enabled` | bool | Whether the output is active (Kanshi). |
| `vrr` | int | Variable refresh rate (Kanshi adaptive sync). |

### Kanshi Auto-Profiles

If you import `home/common/optional/desktops/services/kanshi.nix`, Kanshi automatically generates a profile from `osConfig.monitors`:

```nix
services.kanshi.settings = lib.optionals ((lib.length osConfig.monitors) > 0) [
  {
    profile.name = "default";
    profile.outputs = map (m: {
      criteria = m.name;
      status = if m.enabled then "enable" else "disable";
      mode = "${toString m.width}x${toString m.height}@${toString m.refreshRate}Hz";
      scale = m.scale;
      adaptiveSync = m.vrr != 0;
      position = "${toString m.x},${toString m.y}";
    }) osConfig.monitors;
  }
];
```

### HiDPI & HDR

In `host-spec.nix`:
```nix
{
  scaling = "1.5";   # For 4K displays
  hdr = true;        # Enables HDR-aware DPI scaling in SDDM
}
```

When `hdr = true`, SilentSDDM automatically sets:
- `QT_SCREEN_SCALE_FACTORS` and `QT_FONT_DPI` based on `hostSpec.scaling`.

---

## 8. Theming with Stylix & Base16

### What is Stylix?

[Stylix](https://github.com/danth/stylix) is a NixOS/Home-Manager module that automatically applies a single color scheme and wallpaper across your entire system. When enabled, it themes:

- GTK and Qt applications
- Terminal emulators (Ghostty, Kitty)
- Cursor theme
- Fonts
- Boot loader (if supported)
- And many more targets

### What is Base16?

Base16 is a standardized 16-color palette format. Each theme defines:
- `base00`–`base07`: Grayscale (background to foreground)
- `base08`–`base0F`: Accent colors (red, orange, yellow, green, cyan, blue, purple, darkred)

Stylix uses these 16 colors to derive all application-specific color values.

### Enabling Auto-Styling

In `hosts/nixos/<host>/host-spec.nix`:
```nix
{
  isAutoStyled = true;
  theme = "dracula";  # or "gruvbox-dark-medium", "nord", etc.
  wallpaper = /path/to/wallpaper.png;
}
```

When `isAutoStyled = true`, the module `modules/hosts/common/auto-styling.nix` activates Stylix system-wide.

### Available Themes

Themes come from `pkgs.base16-schemes`. Popular options include:
- `dracula`
- `gruvbox-dark-medium`
- `nord`
- `catppuccin-mocha`
- `tokyo-night-dark`

### Custom Palette (Per-Host Override)

You can override the entire 16-color palette for a specific host. The `ghost` host demonstrates this:

```nix
# modules/hosts/common/auto-styling.nix
stylix = {
  # ... standard options ...
}
// lib.optionalAttrs (config.hostSpec.hostName == "ghost") {
  override = {
    scheme = "ascendancy";
    author = "emergentmind";
    base00 = "#282828"; # background
    base01 = "#212F3D"; # lighter background
    base02 = "#504945"; # selection background
    base03 = "#928374"; # comments
    base04 = "#BDAE93"; # dark foreground
    base05 = "#D5C7A1"; # foreground
    base06 = "#EBDBB2"; # light foreground
    base07 = "#fbf1c7"; # lightest foreground
    base08 = "#D05000"; # red
    base09 = "#FE8019"; # orange
    base0A = "#FFCC1B"; # yellow
    base0B = "#B8BB26"; # green
    base0C = "#8F3F71"; # cyan
    base0D = "#458588"; # blue
    base0E = "#FABD2F"; # purple
    base0F = "#B59B4D"; # darkred
  };
};
```

To create your own theme:
1. Pick 16 colors that fit your aesthetic.
2. Add an `override` block like above, either unconditionally or gated by `hostName`.
3. Rebuild.

### Font & Cursor Configuration

Stylix font settings are defined in `modules/hosts/common/auto-styling.nix` and should be kept in sync with `hosts/common/optional/fonts.nix`:

```nix
stylix.fonts = rec {
  monospace = {
    name = "FiraMono Nerd Font";
    package = pkgs.nerd-fonts.fira-mono;
  };
  sansSerif = monospace;
  serif = monospace;
  emoji = {
    package = pkgs.nerd-fonts.symbols-only;
    name = "Nerd Fonts Symbols Only";
  };
  sizes = {
    terminal = 14;
    desktop = 14;
    popups = 12;
  };
};

stylix.cursor = {
  name = "Breeze_Hacked";
  size = 40;
  package = pkgs.breeze-hacked-cursor-theme.override {
    accentColor = "#${config.lib.stylix.colors.base0A}";
  };
};
```

---

## 9. Switching Desktop Environments

### Niri → GNOME

**1. Host level** (`hosts/nixos/<host>/default.nix`):
```nix
# Remove or comment out:
# introdus.niri.enable = true;
# services.displayManager.sddm.wayland.enable = lib.mkForce true;

# Add:
(hosts/common/optional/gnome.nix)
```
Or import it from `hosts/common/optional/`:
```nix
++ (map (f: "hosts/common/optional/${f}") [
  "gnome.nix"
])
```

**2. Home level** (`home/<user>/<host>.nix`):
```nix
++ map (f: "home/common/optional/${f}") [
  "desktops/gnome"    # Replace "desktops/niri"
  # Remove: "desktops/noctalia.nix" if you want vanilla GNOME shell
]
```

**3. Host spec** (`hosts/nixos/<host>/host-spec.nix`):
```nix
{
  defaultDesktop = "gnome";
  useWayland = true;  # GNOME Wayland is supported
}
```

**4. Rebuild**:
```bash
just rebuild <host>
```

### GNOME → Niri

Reverse the steps: remove `gnome.nix`, re-enable `introdus.niri.enable`, swap home modules, set `defaultDesktop = "niri"`.

### Important Differences

| Feature | Niri + Noctalia | GNOME |
|---------|-----------------|-------|
| Display Manager | SDDM (SilentSDDM) | GDM (auto-enabled by `services.desktopManager.gnome.enable`) |
| Shell | Noctalia | GNOME Shell |
| Bar | Noctalia bar | GNOME top panel + Dash to Dock |
| Launcher | Noctalia launcher | GNOME overview |
| Notifications | Noctalia OSD | GNOME notifications |
| Config format | KDL + Nix | dconf + Nix |

---

## 10. Adding a New Compositor (Theoretical)

To add a compositor like **Hyprland** or **Sway**, you need three things:

### 1. System Module
Create `modules/hosts/nixos/hyprland.nix`:
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.<namespace>.hyprland;
in
{
  options.<namespace>.hyprland = {
    enable = lib.mkEnableOption "Enable Hyprland";
  };
  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = pkgs.unstable.hyprland;
    };
    programs.uwsm.waylandCompositors.hyprland = {
      prettyName = "Hyprland";
      comment = "Hyprland compositor managed by UWSM";
      binPath = lib.getExe config.programs.hyprland.package;
    };
  };
}
```

Register it in `modules/hosts/nixos/default.nix` (if using `scanPaths`) or import it manually.

### 2. Home Module
Create `home/common/optional/desktops/hyprland/default.nix`:
```nix
{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.hyprland ];
  home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
  # Or use home-manager's `wayland.windowManager.hyprland` module
}
```

### 3. Host Integration
In the host `default.nix`:
```nix
<namespace>.hyprland.enable = true;
```

In `host-spec.nix`:
```nix
{
  defaultDesktop = "hyprland";
  useWayland = true;
}
```

In the user's home entrypoint:
```nix
++ map (f: "home/common/optional/${f}") [
  "desktops/hyprland"
]
```

### Notes
- Ensure `programs.uwsm` registers the new compositor so SDDM can launch it.
- Kanshi is compositor-agnostic and will work with any wlroots-based compositor.
- Noctalia may or may not integrate with non-Niri compositors; test IPC calls.

---

## 11. Display Manager Alternatives

### SilentSDDM Themes

The `introdus.services.silent-sddm` module exposes a `theme` option:

```nix
introdus.services.silent-sddm = {
  enable = true;
  theme = "rei";  # or another theme from the SilentSDDM package
};
```

Available themes depend on the `silentSDDM` flake input.

### Switching to GDM

If you prefer GDM (e.g., for GNOME):

1. Disable SilentSDDM:
   ```nix
   # introdus.services.silent-sddm.enable = false;
   ```
2. Enable GDM via the GNOME module:
   ```nix
   services.desktopManager.gnome.enable = true;  # This auto-enables GDM
   ```
3. Or explicitly:
   ```nix
   services.displayManager.gdm.enable = true;
   ```

### SDDM Backend (X11 vs Wayland)

By default, SilentSDDM enables X11 (`introdus.services.x11.enable = true`) for compatibility.

To force the Wayland backend:
```nix
services.displayManager.sddm.wayland.enable = lib.mkForce true;
```

> **Caution:** Some GPU/driver combinations fail with SDDM on Wayland. If you get a black screen on boot, revert to X11.

---

## 12. Common Patterns & Quick Reference

### Files You Edit Most Often

| File | Purpose |
|------|---------|
| `hosts/nixos/<host>/host-spec.nix` | Desktop flags, theme, wallpaper, scaling |
| `hosts/nixos/<host>/default.nix` | Enable/disable compositor, DM, audio |
| `hosts/nixos/<host>/monitors.nix` | Display layout, resolution, scale |
| `hosts/nixos/<host>/niri/*.kdl` | Per-host Niri outputs, workspaces, startup |
| `home/<user>/<host>.nix` | Compose desktop home modules |
| `home/common/optional/desktops/noctalia.nix` | Noctalia settings |
| `home/common/optional/desktops/niri/*.kdl` | Global Niri binds, rules, config |
| `modules/hosts/common/auto-styling.nix` | Stylix overrides, custom palettes |

### Build Commands

```bash
# Enter dev shell
nix develop

# Check configuration
just check <host>

# Rebuild and switch
just rebuild <host>

# Format all files
nix fmt

# Update flake inputs
just update <host>
```

### Disabling the Desktop Entirely (Headless / Server)

In `host-spec.nix`:
```nix
{
  isServer = true;
  useWindowManager = false;
}
```

In `default.nix`, do **not** import any desktop or display manager modules.

---

## Appendix: Noctalia IPC Calls in Niri Binds

Noctalia exposes a CLI (`noctalia-shell ipc call <module> <action>`) that is used throughout `binds.kdl`:

| Keybinding | Command |
|------------|---------|
| `Super+Space` | `noctalia-shell ipc call launcher toggle` |
| `Super+Shift+Space` | `noctalia-shell ipc call launcher command` |
| `Super+Shift+E` | `noctalia-shell ipc call sessionMenu toggle` |
| `Super+Comma` | `noctalia-shell ipc call settings open` |
| `XF86AudioRaiseVolume` | `noctalia-shell ipc call volume increase` |
| `XF86AudioLowerVolume` | `noctalia-shell ipc call volume decrease` |
| `XF86AudioPlay` | `noctalia-shell ipc call media playPause` |
| `XF86MonBrightnessUp` | `noctalia-shell ipc call brightness increase` |

If you switch to a different compositor, these binds remain valid as long as `noctalia-shell` is in `$PATH`.
