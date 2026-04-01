{ lib, ... }:
{
  introdus.neovim = {
    enable = true;
    fontSize = 14;
    wrapper = "emergentvim";
  };
  # My custom neovim wrapper, built on top of the introdus neovim base, is enabled by the above
  # and exposed in the config as wrappers.neovim.
  wrappers.neovim = {
    settings = {
      # Set impure paths to allow hot reloading of `plugin/`, `snippets/`, etc
      unwrappedConfig = "/home/ta/src/nix/neovim";
      baseConfig = lib.mkForce "/home/ta/src/nix/introdus/ta/wrappers/neovim";
      devMode = true;
      neovide = true;
      terminalMode = true;
    };
  };
}
