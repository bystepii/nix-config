{
  introdus.firefox = {
    # auto-enabled by introdus for hosts where hostSpec.useWindowManager is true
    profileName = "main";
    profileID = 0;
  };

  imports = [
    ./brave.nix
    ./chromium.nix
  ];
}
