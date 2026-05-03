{
  # lib,
  pkgs,
  # inputs,
  # osConfig,
  ...
}:
{
  # FIXME: emergentvim wrapper disabled globally — configure plain neovim or re-enable later
  introdus.neovim = {
    # enable = true;
    enable = false;
    # fontSize = 14;
    wrapper = "emergentvim";
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

  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;
  };
}
