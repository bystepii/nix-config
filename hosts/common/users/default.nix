{
  inputs,
  pkgs,
  config,
  lib,
  isDarwin,
  ...
}:
let
  platform = if isDarwin then "darwin" else "nixos";
  inherit (config) hostSpec;

  genPubKeyList =
    user:
    let
      keyPath = lib.custom.relativeToRoot "hosts/common/users/${user}/keys";
    in
    if lib.pathExists keyPath then
      lib.lists.forEach (lib.filesystem.listFilesRecursive keyPath) (key: lib.readFile key)
    else
      [ ];

  fullPathIfExists =
    path:
    let
      fullPath = lib.custom.relativeToRoot path;
      hasDefault = builtins.pathExists "${fullPath}/default.nix";
      isNixFile = lib.hasSuffix ".nix" path;
    in
    lib.optional ((lib.pathExists fullPath) && (isNixFile || hasDefault)) fullPath;
in
{
  # No matter what environment we are in we want these tools for root and users
  programs.zsh.enable = true;
  programs.git.enable = true;
  environment.systemPackages = [
    pkgs.just
    pkgs.rsync
  ];

  users = {
    users =
      (lib.mergeAttrsList (
        map (user: {
          "${user}" =
            let
              platformPath = lib.custom.relativeToRoot "hosts/common/users/${user}/${platform}.nix";
              hasSops = config ? sops && config.sops ? secrets;
              hasSopsPassword = hasSops && builtins.hasAttr "passwords/${user}" config.sops.secrets;
              sopsHashedPasswordFile =
                if (!hostSpec.isMinimal) && hasSopsPassword then
                  config.sops.secrets."passwords/${user}".path
                else
                  "";
            in
            {
              name = user;
              shell = pkgs.bash;
              home = if isDarwin then "/Users/${user}" else "/home/${user}";
              openssh.authorizedKeys.keys = genPubKeyList user;
            }
            // lib.optionalAttrs (sopsHashedPasswordFile != "") {
              hashedPasswordFile = sopsHashedPasswordFile;
            }
            // lib.optionalAttrs (lib.pathExists platformPath) (
              import platformPath {
                inherit config lib;
              }
            );
        }) hostSpec.users
      ))
      // lib.optionalAttrs (!isDarwin) {
        root = {
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = genPubKeyList hostSpec.primaryUsername;
        };
      };
  }
  // lib.optionalAttrs (!isDarwin) {
    mutableUsers = false;
  };

  # Create ssh sockets directory for controlpaths when home-manager is not loaded (i.e. isMinimal)
  systemd.tmpfiles.rules =
    let
      user = config.users.users.${hostSpec.primaryUsername}.name;
      group = config.users.users.${hostSpec.primaryUsername}.group;
    in
    [
      "d /home/${hostSpec.primaryUsername}/.ssh 0750 ${user} ${group} -"
      "d /home/${hostSpec.primaryUsername}/.ssh/sockets 0750 ${user} ${group} -"
    ];
}
// lib.optionalAttrs (inputs ? "home-manager") {
  home-manager = {
    extraSpecialArgs = {
      inherit pkgs inputs;
      hostSpec = config.hostSpec;
    };
    users = lib.mergeAttrsList (
      map (user: {
        "${user}".imports = lib.flatten [
          (lib.optional (!hostSpec.isMinimal) (
            map fullPathIfExists [
              "home/${user}/${hostSpec.hostName}.nix"
              "home/${user}/common"
              "home/${user}/common/${platform}.nix"
            ]
          ))
          (
            { ... }:
            {
              home = {
                stateVersion = lib.mkDefault "24.11";
                homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
                username = user;
              };
            }
          )
        ];
      }) hostSpec.users
    );
  };
}
