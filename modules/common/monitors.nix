# Shared monitor schema options for workspace/display modules.
# This module only defines schema and assertions; host/user modules consume it as needed.

{ lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.monitors = mkOption {
    type = types.listOf (
      types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "DP-1";
          };
          primary = mkOption {
            type = types.bool;
            default = false;
          };
          noBar = mkOption {
            type = types.bool;
            default = false;
          };
          width = mkOption {
            type = types.int;
            example = 1920;
          };
          height = mkOption {
            type = types.int;
            example = 1080;
          };
          refreshRate = mkOption {
            type = types.int;
            default = 60;
          };
          x = mkOption {
            type = types.int;
            default = 0;
          };
          y = mkOption {
            type = types.int;
            default = 0;
          };
          scale = mkOption {
            type = types.number;
            default = 1.0;
          };
          transform = mkOption {
            type = types.int;
            default = 0;
          };
          enabled = mkOption {
            type = types.bool;
            default = true;
          };
          workspace = mkOption {
            type = types.nullOr types.str;
            description = "Defines a workspace that should persist on this monitor.";
            default = null;
          };
          vrr = mkOption {
            type = types.int;
            description = "Variable Refresh Rate values aligned with common WM conventions: 0=off, 1=on, 2=fullscreen only.";
            default = 0;
          };
        };
      }
    );
    default = [ ];
  };

  config = {
    assertions = [
      {
        assertion =
          ((lib.length config.monitors) != 0)
          -> ((lib.length (lib.filter (m: m.primary) config.monitors)) == 1);
        message = "Exactly one monitor must be set to primary.";
      }
    ];
  };
}
