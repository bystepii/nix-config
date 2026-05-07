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

## 6. Noctalia-Shell Deep Dive

Noctalia is your desktop shell: top bar, app launcher, control center, notifications, OSD, wallpaper manager, and session menu.

### Module Import & Waybar Conflict

The module is imported from the flake input:
```nix
imports = [ inputs.noctalia.homeModules.default ];
```

Noctalia explicitly disables Waybar because it replaces it entirely:
```nix
programs.waybar.enable = lib.mkForce false;
```
Do not try to run both simultaneously.

### Plugin System

Noctalia supports external plugins from remote repositories.

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
    rss-feed        = { enabled = true; sourceUrl = url; };
    timer           = { enabled = true; sourceUrl = url; };
  };
  version = 2;
};
```

| Field | Description |
|-------|-------------|
| `sources` | Array of plugin repositories. |
| `states.<name>.enabled` | Whether to load a plugin. |
| `states.<name>.sourceUrl` | Where to fetch the plugin from. |
| `version` | Plugin manifest version. Keep at `2`. |

Plugin-specific settings go under `pluginSettings`:
```nix
programs.noctalia-shell.pluginSettings = {
  privacy-indicator = {
    activeColor = "error";   # Color when a privacy device is active
    hideInactive = true;     # Hide the widget when nothing is recording
  };
  timer = {
    compactMode = false;     # Smaller timer widget
    defaultDuration = 0;     # Default countdown in seconds (0 = none)
  };
};
```

---

### Core Settings Reference (~50 Most Important Fields)

Fields are grouped by functional area. All sit under `programs.noctalia-shell.settings`.

#### A. General Appearance & Behavior

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `animationSpeed` | float | `1` | Multiplier for all shell animations (`0` = instant, `2` = slow). |
| `animationDisabled` | bool | `false` | Globally disable all animations. |
| `avatarImage` | path | nix-assets | User avatar shown in lock screen and control center. |
| `clockFormat` | str | `"HH:mm "` | Format string for bar clock. |
| `clockStyle` | str | `"custom"` | Clock rendering style. `"custom"` uses `clockFormat`. |
| `compactLockScreen` | bool | `true` | Use a smaller, centered lock screen layout. |
| `dimmerOpacity` | float | `0.25` | Opacity of the background dimmer when a panel is open. |
| `enableBlurBehind` | bool | `true` | Blur the wallpaper behind panels and popups. |
| `enableShadows` | bool | `true` | Drop shadows for panels and floating widgets. |
| `forceBlackScreenCorners` | bool | `false` | Force black corners instead of rounded screen corners. |
| `lockOnSuspend` | bool | `true` | Automatically lock the session on suspend. |
| `lockScreenBlur` | float | `0.25` | Blur strength on the lock screen background. |
| `lockScreenTint` | float | `0.6` | Dark tint overlay on the lock screen background. |
| `radiusRatio` | float | `1` | Corner roundness multiplier for UI elements. |
| `scaleRatio` | float | `1` | Global UI scale multiplier. |
| `showScreenCorners` | bool | `false` | Show visual indicators at screen corners. |
| `smoothScrollEnabled` | bool | `true` | Enable smooth scrolling in lists. |
| `telemetryEnabled` | bool | `false` | Send anonymous usage data. |

#### B. App Launcher

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `position` | str | `"center"` | Launcher position: `"center"`, `"top"`, `"bottom"`. |
| `viewMode` | str | `"list"` | Layout: `"list"` or `"grid"`. |
| `iconMode` | str | `"tabler"` | Icon set: `"tabler"`, `"font-awesome"`, etc. |
| `density` | str | `"default"` | Item density: `"compact"`, `"default"`, `"comfortable"`. |
| `pinnedApps` | [str] | `[]` | Apps always shown at the top of the launcher. |
| `terminalCommand` | str | `"ghostty -e"` | Command used when launching terminal apps. |
| `enableClipboardHistory` | bool | `true` | Show clipboard history in launcher. |
| `enableWindowsSearch` | bool | `true` | Include open windows in search results. |
| `enableSessionSearch` | bool | `true` | Include session actions in search results. |
| `enableSettingsSearch` | bool | `true` | Include settings pages in search results. |
| `sortByMostUsed` | bool | `true` | Sort apps by usage frequency. |
| `showCategories` | bool | `true` | Show app category sidebar. |
| `ignoreMouseInput` | bool | `false` | Ignore mouse when navigating with keyboard. |

#### C. Bar Layout & Style

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `position` | str | `"top"` | Bar edge: `"top"`, `"bottom"`, `"left"`, `"right"`. |
| `displayMode` | str | `"always_visible"` | Visibility: `"always_visible"`, `"auto_hide"`, `"overlay"`. |
| `barType` | str | `"simple"` | Visual style: `"simple"`, `"floating"`, etc. |
| `density` | str | `"comfortable"` | Widget density inside the bar. |
| `autoHideDelay` | int | `500` | Milliseconds before hiding in auto-hide mode. |
| `autoShowDelay` | int | `150` | Milliseconds before showing when hovering the edge. |
| `marginHorizontal` | int | `4` | Left/right margin in pixels. |
| `marginVertical` | int | `4` | Top/bottom margin in pixels. |
| `frameRadius` | int | `12` | Corner radius of the bar frame. |
| `frameThickness` | int | `8` | Thickness of the bar frame border. |
| `fontScale` | float | `1.25` | Font size multiplier for bar text. |
| `backgroundOpacity` | float | `1` | Opacity of the bar background (`0` = invisible, `1` = solid). |
| `useSeparateOpacity` | bool | `true` | Allow different opacity for widgets vs background. |

#### D. Bar Widgets

The bar is split into three arrays: `bar.widgets.left`, `bar.widgets.center`, `bar.widgets.right`. Each element is an attribute set with at minimum an `id` field.

**Common properties** (available on most widgets):

| Property | Type | Description |
|----------|------|-------------|
| `id` | str | **Required.** Widget identifier. |
| `iconColor` | str | Color key for the icon: `"none"`, `"primary"`, `"secondary"`, `"tertiary"`, `"error"`. |
| `textColor` | str | Color key for text labels. |
| `colorizeIcons` | bool | Whether to tint icons with the chosen `iconColor`. |
| `enableScrollWheel` | bool | Allow mouse-wheel interaction on this widget. |

**Widget-specific properties:**

| Widget ID | Unique Properties | Description |
|-----------|-------------------|-------------|
| `Spacer` | `width` (int) | Empty gap of N pixels. |
| `Workspace` | `labelMode` (`"name"` / `"icon"` / `"number"`), `showBadge` (bool), `hideUnoccupied` (bool), `pillSize` (float), `focusedColor` (str), `occupiedColor` (str), `emptyColor` (str), `iconScale` (float), `fontWeight` (str), `characterCount` (int), `groupedBorderOpacity` (float) | Workspace switcher. `pillSize` controls the active indicator height. |
| `plugin:privacy-indicator` | `activeColor` (str), `hideInactive` (bool), `micFilterRegex` (str) | Shows microphone/camera usage. |
| `ActiveWindow` | `showIcon` (bool), `showText` (bool), `textColor` (str), `hideMode` (`"hidden"` / `"active"`), `maxWidth` (int), `scrollingMode` (`"hover"` / `"always"`), `useFixedWidth` (bool) | Displays the focused window title. |
| `plugin:timer` | `compactMode` (bool), `defaultDuration` (int), `iconColor` (str), `textColor` (str) | Countdown timer widget. |
| `NotificationHistory` | `showUnreadBadge` (bool), `unreadBadgeColor` (str), `hideWhenZero` (bool), `hideWhenZeroUnread` (bool) | Recent notification list. |
| `plugin:rss-feed` | *(none)* | RSS ticker from configured feeds. |
| `Tray` | `drawerEnabled` (bool), `hidePassive` (bool), `pinned` ([str]), `blacklist` ([str]), `chevronColor` (str) | System tray icons. `pinned` keeps specific icons always visible. |
| `Volume` | `displayMode` (`"alwaysShow"` / `"onhover"`), `middleClickCommand` (str) | Audio volume control. |
| `Network` / `Bluetooth` | `displayMode` (`"alwaysShow"` / `"onhover"`) | Network/Bluetooth status. |
| `Battery` | `displayMode` (`"graphic-clean"` / `"text"`), `hideIfNotDetected` (bool), `hideIfIdle` (bool), `showNoctaliaPerformance` (bool), `showPowerProfiles` (bool) | Battery percentage and status. |
| `Clock` | `formatHorizontal` (str), `formatVertical` (str), `clockColor` (str), `tooltipFormat` (str), `useCustomFont` (bool), `customFont` (str) | Date/time display. Formats use `strftime` syntax. |

Example bar layout:
```nix
programs.noctalia-shell.settings.bar.widgets = {
  left = [
    { id = "Spacer"; width = 30; }
    { id = "Workspace"; labelMode = "name"; showBadge = true; pillSize = 0.85; }
  ];
  center = [
    { id = "plugin:privacy-indicator"; activeColor = "error"; hideInactive = true; }
    { id = "ActiveWindow"; showIcon = true; showText = true; textColor = "secondary"; }
    { id = "plugin:timer"; compactMode = false; }
  ];
  right = [
    { id = "NotificationHistory"; showUnreadBadge = true; unreadBadgeColor = "error"; }
    { id = "plugin:rss-feed"; }
    { id = "Tray"; drawerEnabled = true; }
    { id = "Volume"; displayMode = "alwaysShow"; middleClickCommand = "pwvucontrol || pavucontrol"; }
    { id = "Network"; displayMode = "onhover"; }
    { id = "Bluetooth"; displayMode = "onhover"; }
    { id = "Battery"; displayMode = "graphic-clean"; hideIfNotDetected = true; }
    { id = "Clock"; formatHorizontal = "HH:mm  yy.MM.dd.ddd"; clockColor = "secondary"; }
    { id = "Spacer"; width = 30; }
  ];
};
```

#### E. Notifications

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `true` | Enable the notification daemon. |
| `location` | str | `"top_right"` | Popup corner: `"top_left"`, `"top_right"`, `"bottom_left"`, `"bottom_right"`. |
| `density` | str | `"default"` | Notification card density. |
| `normalUrgencyDuration` | int | `8` | Seconds normal notifications stay visible. |
| `criticalUrgencyDuration` | int | `15` | Seconds critical notifications stay visible. |
| `lowUrgencyDuration` | int | `3` | Seconds low-priority notifications stay visible. |
| `saveToHistory` | attrs | all `true` | Whether to persist normal/critical/low notifications to history. |
| `clearDismissed` | bool | `true` | Auto-remove dismissed notifications from history. |
| `overlayLayer` | bool | `true` | Render notifications above fullscreen windows. |
| `sounds.enabled` | bool | `false` | Play notification sounds. |

#### F. Wallpaper

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `true` | Enable wallpaper management. |
| `directory` | str | `...` | Path to a folder containing wallpaper images. |
| `automationEnabled` | bool | `true` | Auto-cycle wallpapers. |
| `wallpaperChangeMode` | str | `"random"` | Cycle mode: `"random"`, `"sequential"`. |
| `randomIntervalSec` | int | `3600` | Seconds between auto-changes. |
| `transitionType` | [str] | `["fade" "disc" ...]` | Animation types used when switching. |
| `transitionDuration` | int | `1500` | Transition length in milliseconds. |
| `fillMode` | str | `"crop"` | How images fit the screen: `"crop"`, `"fit"`, `"stretch"`, `"tile"`. |
| `setWallpaperOnAllMonitors` | bool | `true` | Use the same wallpaper on every monitor. |
| `useSolidColor` | bool | `false` | Use a flat color instead of an image. |
| `solidColor` | str | `"#1a1a2e"` | Hex color when `useSolidColor = true`. |
| `useWallhaven` | bool | `false` | Fetch wallpapers from wallhaven.cc. |
| `wallhavenApiKey` | str | `""` | API key for Wallhaven (optional). |
| `wallhavenQuery` | str | `""` | Search query for Wallhaven. |
| `favorites` | [str] | `[]` | Filenames marked as favorites. |
| `linkLightAndDarkWallpapers` | bool | `true` | Pair light and dark variants. |

#### G. Session Menu

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `position` | str | `"center"` | Menu position: `"center"`, `"top"`, `"bottom"`. |
| `largeButtonsStyle` | bool | `true` | Use large, icon-only power buttons. |
| `largeButtonsLayout` | str | `"single-row"` | Layout of buttons: `"single-row"`, `"multi-row"`. |
| `enableCountdown` | bool | `false` | Show a countdown before executing a power action. |
| `countdownDuration` | int | `1000` | Countdown length in milliseconds. |
| `showKeybinds` | bool | `true` | Show keyboard shortcuts next to each action. |
| `showHeader` | bool | `true` | Show the user avatar/name header. |

The `powerOptions` array defines which actions appear and in what order:

| Property | Description |
|----------|-------------|
| `action` | Built-in action: `"lock"`, `"suspend"`, `"hibernate"`, `"reboot"`, `"logout"`, `"shutdown"`, `"rebootToUefi"`, `"userspaceReboot"`. |
| `enabled` | Whether the button is shown. |
| `keybind` | Single-character keyboard shortcut. |
| `countdownEnabled` | Whether this specific action uses the countdown. |
| `command` | Custom shell command to run instead of the built-in action (leave empty for default). |

Example:
```nix
programs.noctalia-shell.settings.sessionMenu.powerOptions = [
  { action = "lock";        enabled = true; keybind = "1"; countdownEnabled = true; }
  { action = "suspend";     enabled = true; keybind = "2"; countdownEnabled = true; }
  { action = "reboot";      enabled = true; keybind = "3"; countdownEnabled = true; }
  { action = "shutdown";    enabled = true; keybind = "4"; countdownEnabled = true; }
  { action = "rebootToUefi"; enabled = true; keybind = "5"; countdownEnabled = true; }
];
```

#### H. Control Center

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `position` | str | `"center"` | Panel position: `"center"`, `"left"`, `"right"`. |
| `cards` | [attrs] | `...` | Ordered list of cards to display. Each card has `id` and `enabled`. |
| `diskPath` | str | `"/"` | Filesystem path monitored by the storage card. |

Available card IDs: `profile-card`, `shortcuts-card`, `audio-card`, `brightness-card`, `weather-card`, `media-sysmon-card`.

Shortcuts are quick-toggle buttons shown above or below cards:
```nix
shortcuts = {
  left = [ { id = "Network"; } { id = "Bluetooth"; } { id = "WallpaperSelector"; } ];
  right = [ { id = "Notifications"; } { id = "PowerProfile"; } ];
};
```

#### I. Audio & Media

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `preferredPlayer` | str | `"spotify"` | MPRIS player name for media controls. |
| `volumeStep` | int | `5` | Percentage change per volume keypress. |
| `volumeFeedback` | bool | `false` | Play a sound on volume change. |
| `volumeOverdrive` | bool | `false` | Allow volume above 100%. |
| `spectrumFrameRate` | int | `30` | FPS of the audio visualizer bar. |
| `visualizerType` | str | `"linear"` | Visualizer style: `"linear"`, `"circular"`. |
| `spectrumMirrored` | bool | `true` | Mirror the visualizer horizontally. |

#### J. System Monitor Thresholds

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cpuWarningThreshold` | int | `80` | CPU % that triggers a warning color. |
| `cpuCriticalThreshold` | int | `90` | CPU % that triggers a critical color. |
| `memWarningThreshold` | int | `80` | RAM % warning threshold. |
| `memCriticalThreshold` | int | `90` | RAM % critical threshold. |
| `batteryWarningThreshold` | int | `20` | Battery % warning. |
| `batteryCriticalThreshold` | int | `5` | Battery % critical. |
| `enableDgpuMonitoring` | bool | `false` | Monitor discrete GPU metrics. |

#### K. Idle & Power

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `false` | Enable idle management (dim, lock, suspend). |
| `lockTimeout` | int | `660` | Seconds of inactivity before locking. |
| `screenOffTimeout` | int | `600` | Seconds before turning off the screen. |
| `suspendTimeout` | int | `1800` | Seconds before suspending. |
| `fadeDuration` | int | `5` | Seconds to fade the screen to black before lock. |
| `lockCommand` | str | `""` | Custom command to run for locking. |
| `screenOffCommand` | str | `""` | Custom command to turn off the screen. |

#### L. Color Schemes

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `darkMode` | bool | `true` | Use dark colors. |
| `generationMethod` | str | `"tonal-spot"` | Algorithm for generating palette: `"tonal-spot"`, `"neutral"`, `"vibrant"`. |
| `schedulingMode` | str | `"off"` | Auto-toggle dark mode: `"off"`, `"sunrise-sunset"`, `"manual"`. |
| `manualSunrise` | str | `"06:30"` | Sunrise time when scheduling is manual. |
| `manualSunset` | str | `"18:30"` | Sunset time when scheduling is manual. |
| `useWallpaperColors` | bool | `false` | Generate palette from the current wallpaper. |
| `predefinedScheme` | str | `"default"` | Use a built-in scheme instead of generating one. |

#### M. Location & Weather

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | str | `"Calgary"` | City name for weather lookup. |
| `weatherEnabled` | bool | `true` | Show weather in calendar and control center. |
| `showCalendarWeather` | bool | `true` | Show weather widget in the calendar popup. |
| `useFahrenheit` | bool | `false` | Use Fahrenheit instead of Celsius. |
| `autoLocate` | bool | `false` | Detect location automatically via IP. |

#### N. Night Light

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `false` | Reduce blue light in the evening. |
| `autoSchedule` | bool | `true` | Enable/disable based on sunrise/sunset. |
| `dayTemp` | str | `"6500"` | Color temperature during the day (Kelvin). |
| `nightTemp` | str | `"4000"` | Color temperature at night (Kelvin). |

#### O. Performance Mode

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `disableDesktopWidgets` | bool | `true` | Hide floating desktop widgets in performance mode. |
| `disableWallpaper` | bool | `true` | Hide wallpaper in performance mode (solid color fallback). |

#### P. UI Global

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `fontDefaultScale` | float | `1` | Scale factor for default fonts. |
| `fontFixedScale` | float | `1` | Scale factor for monospace fonts. |
| `translucentWidgets` | bool | `true` | Allow widgets to be semi-transparent. |
| `panelBackgroundOpacity` | float | `0.75` | Default opacity for popup panels. |
| `panelsAttachedToBar` | bool | `true` | Attach popups to the bar edge rather than floating freely. |
| `tooltipsEnabled` | bool | `true` | Show tooltips on hover. |
| `settingsPanelMode` | str | `"window"` | Settings UI mode: `"window"`, `"popup"`. |

#### Q. Hooks

Hooks let you run external commands when Noctalia events occur.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `false` | Master switch for hooks. |
| `startup` | str | `""` | Command run once after Noctalia starts. |
| `screenLock` | str | `""` | Command run when the screen locks. |
| `screenUnlock` | str | `""` | Command run when the screen unlocks. |
| `wallpaperChange` | str | `""` | Command run after wallpaper changes. |
| `darkModeChange` | str | `""` | Command run when dark mode toggles. |
| `colorGeneration` | str | `""` | Command run after color palette is regenerated. |
| `performanceModeEnabled` | str | `""` | Command run when performance mode turns on. |
| `performanceModeDisabled` | str | `""` | Command run when performance mode turns off. |

#### R. Dock

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `false` | Show a dock at the screen edge. |
| `position` | str | `"bottom"` | Dock edge: `"bottom"`, `"left"`, `"right"`, `"top"`. |
| `dockType` | str | `"floating"` | `"floating"` or `"panel"`. |
| `displayMode` | str | `"auto_hide"` | Visibility: `"always_visible"`, `"auto_hide"`, `"overlay"`. |
| `pinnedApps` | [str] | `[]` | Apps permanently shown in the dock. |
| `size` | float | `1` | Dock scale multiplier. |
| `indicatorColor` | str | `"primary"` | Color of the active-app indicator dot/line. |
| `indicatorThickness` | int | `3` | Thickness of the indicator in pixels. |
| `groupApps` | bool | `false` | Group multiple windows of the same app. |
| `groupClickAction` | str | `"cycle"` | Behavior when clicking a group: `"cycle"`, `"menu"`. |

#### S. OSD

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | bool | `true` | Show on-screen display popups (volume, brightness). |
| `location` | str | `"top_right"` | OSD corner. |
| `autoHideMs` | int | `2000` | Milliseconds before the OSD fades out. |
| `enabledTypes` | [int] | `[0 1 2]` | Which OSD types are enabled: `0`=volume, `1`=brightness, `2`=misc. |

---

### Colors Deep Dive

Noctalia uses Material-You-style color roles. Your config maps them from Stylix base16 colors.

| Color Key | Stylix Base | UI Elements It Controls |
|-----------|-------------|------------------------|
| `Surface` | `base00` | **Backgrounds**: bar background, popup backdrops, card fills, panel surfaces. |
| `mOnSurface` | `base03` | **Primary text** on panels and popups: clock text, labels, titles. |
| `mSurfaceVariant` | `base01` | **Secondary backgrounds**: input fields, inactive list items, subtle card variants. |
| `mOnSurfaceVariant` | `base04` | **Secondary text**: placeholders, disabled labels, hints, inactive workspace names. |
| `mPrimary` | `base02` | **Accent**: active workspace pill, toggle switches ON, selected buttons, focused highlights. |
| `mOnPrimary` | `base0E` | **Text on accent**: labels sitting on Primary-colored backgrounds. |
| `mSecondary` | `base0F` | **Secondary accent**: secondary buttons, inactive tabs, less prominent interactive elements. |
| `mOnSecondary` | `base01` | **Text on secondary accent**. |
| `mTertiary` | `base01` | **Subtle accent**: hover highlights, dividers, inactive indicators, unimportant toggles. |
| `mOnTertiary` | `base0F` | **Text on subtle accent**. |
| `mHover` | `base01` | **Hover state**: background color when mouse hovers over buttons, list items, or widgets. |
| `mOnHover` | `base0A` | **Text during hover**: label color when an element is hovered. |
| `mError` | `base08` | **Error / danger**: error states, destructive actions, critical notification badges, low battery. |
| `mOnError` | `base00` | **Text on error backgrounds**. |
| `mOutline` | `base01` | **Borders**: outlines around focused elements, separators between widgets, card borders. |
| `mShadow` | hardcoded `#000000` | **Drop shadows** behind panels, popups, floating widgets, and the bar. |

If Stylix is disabled (`isAutoStyled = false`), replace the `config.lib.stylix.colors` references with raw hex strings:
```nix
programs.noctalia-shell.colors = {
  Surface = "#282828";
  mOnSurface = "#928374";
  mPrimary = "#504945";
  # ... etc
};
```

---

### Settings Snapshot Timer

Because Noctalia stores runtime settings in `~/.config/noctalia/settings.json`, a systemd timer snapshots changes hourly:

- **Timer:** `systemd.user.timers.noctalia-snapshot-settings`
- **Service:** `systemd.user.services.noctalia-snapshot-settings`
- **Backups:** `~/.cache/noctalia/backup/settings_YYYYMMDD_HHMMSS.json`
- **Retention:** Max 5 backups

This lets you port runtime GUI tweaks back into your Nix expression later.

---

### Quick Reference: "I want to change X"

| I want to... | Edit this field |
|--------------|-----------------|
| Change bar position | `settings.bar.position` |
| Hide the bar | `settings.bar.displayMode = "auto_hide"` |
| Add apps to launcher favorites | `settings.appLauncher.pinnedApps` |
| Change launcher icon style | `settings.appLauncher.iconMode` |
| Change clock format | `settings.general.clockFormat` |
| Change weather city | `settings.location.name` |
| Enable night light | `settings.nightLight.enabled = true` |
| Change wallpaper folder | `settings.wallpaper.directory` |
| Disable wallpaper auto-change | `settings.wallpaper.automationEnabled = false` |
| Add/remove session menu buttons | `settings.sessionMenu.powerOptions` |
| Change volume step size | `settings.audio.volumeStep` |
| Show dock | `settings.dock.enabled = true` |
| Pin apps to dock | `settings.dock.pinnedApps` |
| Change notification position | `settings.notifications.location` |
| Disable blur | `settings.general.enableBlurBehind = false` |
| Slow down animations | `settings.general.animationSpeed = 2` |
| Change UI scale | `settings.general.scaleRatio` |
| Change accent color | `settings.colors.mPrimary` (or Stylix theme) |
| Run script on startup | `settings.hooks.startup` |
| Enable auto-lock | `settings.idle.enabled = true` |

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
