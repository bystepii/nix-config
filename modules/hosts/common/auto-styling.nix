{
  pkgs,
  inputs,
  config,
  lib,
  isDarwin,
  ...
}:
let
  platform = if isDarwin then "darwin" else "nixos";
  platformModules = "${platform}Modules";
in
{
  imports = [
    inputs.stylix.${platformModules}.stylix
  ];

  # Also see modules/home/auto-styling.nix
  config = lib.mkIf config.hostSpec.isAutoStyled {
    stylix = {
      enable = true;
      autoEnable = true;
      polarity = "dark";
      image = config.hostSpec.wallpaper;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.hostSpec.theme}.yaml";

      opacity = {
        applications = 1.0;
        terminal = 1.0;
        desktop = 1.0;
        popups = 0.8;
      };

      cursor = lib.mkForce {
        name = "Breeze_Hacked";
        size = 40;
        package = pkgs.breeze-hacked-cursor-theme.override {
          accentColor = "#${config.lib.stylix.colors.base0A}"; # the main cursor colour (base0A is typically the yellow of a base16 color scheme)
          # baseColor = "";
          # borderColor = "";
          # logoColor = "";
        };
      };

      # FIXME: This needs to be synchronized with fonts.nix
      fonts = rec {
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
          #FiraCode/FiraMono is great but hard to read at 12 on 4k
          terminal = 14;
          desktop = 14;
          popups = 12;
        };
      };
      # program specific exclusions
      #targets.foo = {
      #  enable = true;
      #  property = bar;
      #};
    }
    // lib.optionalAttrs (config.hostSpec.hostName == "ghost") {
      #FIXME(stylix): upstreamed to https://github.com/tinted-theming/schemes -
      #  stylix not caught up yet
      override = {
        scheme = "ascendancy";
        author = "emergentmind";
        base00 = "#282828"; # ----      background
        base01 = "#212F3D"; # ---       lighter background status bar
        base02 = "#504945"; # --        selection background
        base03 = "#928374"; # -         Comments, Invisibles, Line highlighting
        base04 = "#BDAE93"; # +         dark foreground status bar
        base05 = "#D5C7A1"; # ++        foreground, caret, delimiters, operators
        base06 = "#EBDBB2"; # +++       light foreground, rarely used
        base07 = "#fbf1c7"; # ++++      lightest foreground, rarely used
        base08 = "#D05000"; # red       vars, xml tags, markup link text, markup lists, diff deleted
        base09 = "#FE8019"; # orange    Integers, Boolean, Constants, XML Attributes, Markup Link Url
        base0A = "#FFCC1B"; # yellow    Classes, Markup Bold, Search Text Background
        base0B = "#B8BB26"; # green     Strings, Inherited Class, Markup Code, Diff Inserted
        base0C = "#8F3F71"; # cyan      Support, Regular Expressions, Escape Characters, Markup Quotes
        base0D = "#458588"; # blue      Functions, Methods, Attribute IDs, Headings
        base0E = "#FABD2F"; # purple    Keywords, Storage, Selector, Markup Italic, Diff Changed
        base0F = "#B59B4D"; # darkred   Deprecated Highlighting for Methods and Functions, Opening/Closing Embedded Language Tags
      };
    };
  };
}
