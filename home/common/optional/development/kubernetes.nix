# Kubernetes / Helm Dev Tools
{
  lib,
  pkgs,
  config,
  inputs,
  secrets,
  ...
}:
let
  sopsFolder = (toString inputs.nix-secrets) + "/sops";
in
{
  home.packages = lib.attrValues {
    inherit (pkgs)
      kubectl
      kubernetes-helm
      ;
  };

  sops.secrets = {
    "kube/ca" = {
      sopsFile = "${sopsFolder}/shared.yaml";
    };
    "kube/clientCert" = {
      sopsFile = "${sopsFolder}/shared.yaml";
    };
    "kube/clientKey" = {
      sopsFile = "${sopsFolder}/shared.yaml";
    };
  };

  sops.templates."kube-config" = {
    content = ''
      apiVersion: v1
      clusters:
      - cluster:
          certificate-authority-data: ${config.sops.placeholder."kube/ca"}
          server: ${secrets.networking.kube.serverUrl}
        name: kubernetes
      contexts:
      - context:
          cluster: kubernetes
          user: kubernetes-admin
        name: kubernetes-admin@kubernetes
      current-context: kubernetes-admin@kubernetes
      kind: Config
      preferences: {}
      users:
      - name: kubernetes-admin
        user:
          client-certificate-data: ${config.sops.placeholder."kube/clientCert"}
          client-key-data: ${config.sops.placeholder."kube/clientKey"}
    '';
    path = "${config.home.homeDirectory}/.kube/config";
    mode = "0600";
  };
}
