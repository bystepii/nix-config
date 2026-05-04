#HACK: this is all hard-coded to ghost until KDL and nix interplay nicely or I adopt a
#something some sort of wrapper.... another rabbit hole
# as of 26.01.24 the `power-off-monitor` actions listed by `niri msg action`
# haven't actually been implemented in the src:
# `https://github.com/YaLTeR/niri/blob/d7184a04b904e07113f4623610775ae78d32394c/niri-ipc/src/lib.rs#L202`

{
  pkgs,
  osConfig,
  lib,
  ...
}:
let
  nonPrimaryMonitors = lib.filter (m: !m.primary) osConfig.monitors;
  primaryMonitor = lib.findFirst (m: m.primary) null osConfig.monitors;

  #
  # ========== Toggle All Monitors ==========
  #
  # Toggle on/off all monitors. Toggle on all monitors if _any_ monitor is off.

  # TODO(niri):requisite niri actions not yet available

  #
  # ========== Toggle Gaming Mode ==========
  #
  # Toggle on/off all non-primary monitors (gaming mode)

  # TODO(niri):requisite niri actions not yet available

  #
  # ========== Toggle Zen Mode ==========
  #
  # Toggle workspaces on all non-primary monitors between default and empty
  toggleMonitorZen = pkgs.writeShellApplication {
    name = "toggleMonitorZen";
    text = lib.optionalString (primaryMonitor != null) ''
      #!/bin/bash
      ${lib.concatMapStrings (m: ''
        niri msg action focus-monitor "${m.name}" &&
        niri msg action focus-workspace 2 &&
      '') nonPrimaryMonitors}
      niri msg action focus-monitor "${primaryMonitor.name}"
    '';
  };
in
{
  home.packages = lib.optional (primaryMonitor != null) toggleMonitorZen;
}
