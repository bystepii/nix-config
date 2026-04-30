{ lib, ... }:
{
  imports = (
    map lib.custom.relativeToRoot (
      [
        # ========== Required modules ==========
        "home/common/core"
        "home/stepii/common"
      ]
      ++
        # ========== Optional modules ==========
        (map (f: "home/common/optional/${f}") [
        ])
    )
  );

  # home = {
  #   stateVersion = "23.05";
  #   homeDirectory = "/home/stepii";
  #   username = "stepii";
  # };
}
