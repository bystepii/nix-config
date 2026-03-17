# Specifications For Differentiating Hosts
{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.hostSpec = lib.mkOption {
    type = lib.types.submodule {
      freeformType = with lib.types; attrsOf str;
      options = {
        # Data variables that don't dictate configuration settings
        primaryUsername = lib.mkOption {
          type = lib.types.str;
          description = "The primary administrative username of the host";
        };
        primaryDesktopUsername = lib.mkOption {
          type = lib.types.str;
          description = "The primary desktop user on the host";
          default = config.hostSpec.primaryUsername;
        };
        hostName = lib.mkOption {
          type = lib.types.str;
          description = "The hostname of the host";
        };
        email = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "The email of the user";
        };
        work = lib.mkOption {
          default = { };
          type = lib.types.attrsOf lib.types.anything;
          description = "An attribute set of work-related information if isWork is true";
        };
        networking = lib.mkOption {
          default = { };
          type = lib.types.attrsOf lib.types.anything;
          description = "An attribute set of networking information";
        };
        wifi = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate if a host has wifi";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = "local";
          description = "The domain of the host";
        };
        userFullName = lib.mkOption {
          type = lib.types.str;
          default = config.hostSpec.primaryUsername;
          description = "The full name of the user";
        };
        handle = lib.mkOption {
          type = lib.types.str;
          description = "The handle of the user (eg: github user)";
        };
        home = lib.mkOption {
          type = lib.types.str;
          description = "The home directory of the user";
          default =
            let
              user = config.hostSpec.primaryUsername;
            in
            if pkgs.stdenv.isLinux then "/home/${user}" else "/Users/${user}";
        };
        persistFolder = lib.mkOption {
          type = lib.types.str;
          description = "The folder to persist data if impermanence is enabled";
          default = "";
        };

        # Configuration Settings
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of users on the host";
          default = [ config.hostSpec.primaryUsername ];
        };
        isMinimal = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a minimal host";
        };
        isMobile = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a mobile host";
        };
        isProduction = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Used to indicate a production host";
        };
        isServer = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a server host";
        };
        isWork = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that uses work resources";
        };
        isDevelopment = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host used for development";
        };
        isRoaming = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a roaming host for wireless, battery use, etc";
        };
        isRemote = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that is remotely managed";
        };
        isLocal = lib.mkOption {
          type = lib.types.bool;
          default = !config.hostSpec.isRemote;
          description = "Used to indicate a host that is locally managed";
        };
        isAdmin = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host used to administer other systems";
        };
        # Sometimes we can't use pkgs.stdenv.isLinux due to infinite recursion
        isDarwin = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that is darwin";
        };
        isImpermanent = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host with ephemeral root and persisted state";
        };
        useYubikey = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate if the host uses a yubikey";
        };
        voiceCoding = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that uses voice coding";
        };
        isAutoStyled = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that wants auto styling like stylix";
        };
        theme = lib.mkOption {
          type = lib.types.str;
          default = "dracula";
          description = "Theme label used by optional styling modules";
        };
        useNeovimTerminal = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that uses neovim for terminals";
        };
        useWindowManager = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Used to indicate a host that uses a window manager";
        };
        useAtticCache = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Used to indicate a host that uses LAN atticd for caching";
        };
        hdr = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that uses HDR";
        };
        scaling = lib.mkOption {
          type = lib.types.str;
          default = "1";
          description = "Used to indicate what scaling to use. Floating point number";
        };
        useWayland = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Used to indicate a host that uses Wayland";
        };
        useX11 = lib.mkOption {
          type = lib.types.bool;
          default = if config.hostSpec.useWindowManager && (!config.hostSpec.useWayland) then true else false;
          description = "Used to indicate a host that uses X11";
        };
        defaultBrowser = lib.mkOption {
          type = lib.types.str;
          default = "firefox";
          description = "Default browser command";
        };
        defaultEditor = lib.mkOption {
          type = lib.types.str;
          default = "nvim";
          description = "Default editor command";
        };
        defaultMediaPlayer = lib.mkOption {
          type = lib.types.str;
          default = "vlc";
          description = "Default media player command";
        };
        defaultDesktop = lib.mkOption {
          type = lib.types.str;
          default = "niri";
          description = "Default desktop session identifier";
        };
        timeZone = lib.mkOption {
          type = lib.types.str;
          default = "Europe/Madrid";
          description = "Timezone used for host and shared module logic";
        };
      };
    };
  };

  config = {
    assertions =
      let
        # We import these options to HM and NixOS, so need to not fail on HM
        isImpermanent =
          config ? "system" && config.system ? "impermanence" && config.system.impermanence.enable;
      in
      [
        {
          assertion =
            !config.hostSpec.isWork || (config.hostSpec.isWork && !builtins.isNull config.hostSpec.work);
          message = "isWork is true but no work attribute set is provided";
        }
        {
          assertion = !isImpermanent || (isImpermanent && !("${config.hostSpec.persistFolder}" == ""));
          message = "config.system.impermanence.enable is true but no persistFolder path is provided";
        }
        {
          assertion = !(config.hostSpec.voiceCoding && config.hostSpec.useWayland);
          message = "voiceCoding requires X11-compatible tooling and should not be enabled with Wayland";
        }
        {
          assertion = lib.elem config.hostSpec.primaryUsername config.hostSpec.users;
          message = "primaryUsername must be present in hostSpec.users";
        }
      ];
  };
}
