{
  config,
  pkgs,
  inputs,
  ...
}:
let
  sopsFolder = (toString inputs.nix-secrets) + "/sops";
in
{
  home.packages = [ pkgs.minio-client ];

  sops.secrets = {
    "minio/rack/accessKey" = {
      sopsFile = "${sopsFolder}/shared.yaml";
    };
    "minio/rack/secretKey" = {
      sopsFile = "${sopsFolder}/shared.yaml";
    };
  };

  # Ensure ~/.mc directory exists
  home.file.".mc/.keep".text = "";

  sops.templates."mc-config.json" = {
    content = builtins.toJSON {
      version = "10";
      aliases = {
        rack = {
          url = "http://localhost:9000";
          accessKey = config.sops.placeholder."minio/rack/accessKey";
          secretKey = config.sops.placeholder."minio/rack/secretKey";
          api = "S3v4";
          path = "auto";
        };
      };
    };
    path = "${config.home.homeDirectory}/.mc/config.json";
    mode = "0600";
  };
}
