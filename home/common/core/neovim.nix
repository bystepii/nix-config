{
  # lib,
  # pkgs,
  # inputs,
  osConfig,
  ...
}:
{
  # No need to import, aready done by introdus
  # imports = [
  #   (inputs.wrappers.lib.mkInstallModule {
  #     loc = [
  #       "home"
  #       "packages"
  #     ];
  #     name = "neovim";
  #     value = inputs.omnivium.wrapperModules.neovim;
  #   })
  # ];

  # FIXME: emergentvim wrapper disabled globally — configure plain neovim or re-enable later
  introdus.neovim = {
    # enable = true;
    enable = true;
    # fontSize = 14;
    wrapper = "omnivium"; # Override default to avoid "emergentvim" lookup error
  };
  # My custom neovim wrapper, built on top of the introdus neovim base, is enabled by the above
  # and exposed in the config as wrappers.neovim.
  # wrappers.neovim = {
  #   settings =
  #     if osConfig.hostSpec.isIntrodusDev then
  #       {
  #         # Set impure paths to allow hot reloading of `plugin/`, `snippets/`, etc
  #         unwrappedConfig = "/home/ta/src/nix/neovim";
  #         baseConfig = lib.mkForce "/home/ta/src/nix/introdus/ta/wrappers/neovim";
  #       }
  #     else
  #       {
  #         hotReload = false;
  #         # Non-development boxes just use whatever is already in git
  #         baseConfig = lib.mkForce "${inputs.introdus-git}/wrappers/neovim";
  #       };
  # };

  wrappers.neovim = {
    settings =
      if osConfig.hostSpec.isDevelopment then
        {
          # hotReload = true;
          unwrappedConfig = "/home/stepii/src/nix/neovim";
        }
      else
        {
          hotReload = false;
        };
  };

  # programs.neovim = {
  #   enable = true;
  #   package = pkgs.unstable.neovim-unwrapped;
  # };

  # === OMNIVIUM REPLACEMENT (2025-05-13) ===
  # omnivium: standalone neovim config, no introdus dependency
  # home.packages = [
  #   (inputs.omnivium.wrappers.neovim.wrap {
  #     pkgs = pkgs;
  #     settings = {
  #       neovide = osConfig.hostSpec.useWindowManager;
  #       devMode = osConfig.hostSpec.isDevelopment;
  #       terminalMode = osConfig.hostSpec.useNeovimTerminal;
  #       guifont =
  #         let
  #           fonts = lib.optionals (
  #             osConfig ? "fonts"
  #             && osConfig.fonts ? "fontconfig"
  #             && osConfig.fonts.fontconfig ? "defaultFonts"
  #             && osConfig.fonts.fontconfig.defaultFonts ? "monospace"
  #           ) osConfig.fonts.fontconfig.defaultFonts.monospace;
  #           fonts-hashed = map (f: "${f}:h12") fonts;
  #         in
  #         lib.concatStringsSep "," fonts-hashed;
  #     };
  #   })
  # ];

  # wrappers.neovim = {
  #   enable = true;
  #   settings = {
  #     neovide = osConfig.hostSpec.useWindowManager;
  #     devMode = osConfig.hostSpec.isDevelopment;
  #     terminalMode = osConfig.hostSpec.useNeovimTerminal;
  #     guifont =
  #       [ (lib.head osConfig.fonts.fontconfig.defaultFonts.monospace) ]
  #       |> map (f: "${f}:h${toString 12}")
  #       |> lib.concatStringsSep ",";
  #   };
  # };
  #
  # xdg.desktopEntries.nvim-neovide = {
  #   name = "Neovide (Omnivium)";
  #   genericName = "Text Editor";
  #   exec = "nvim-neovide %F";
  #   icon = "nvim";
  #   terminal = false;
  #   categories = [
  #     "Utility"
  #     "TextEditor"
  #   ];
  #   settings.StartupWMClass = "neovide";
  # };
}
