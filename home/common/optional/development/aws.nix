# AWS Dev Tools
{
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.flatten [
    (lib.attrValues {
      inherit (pkgs)
        awscli2 # AWS CLI tool
        eksctl # AWS EKS CLI
        ;
      inherit (pkgs.python313Packages)
        cfn-lint # AWS Cloudformation
        ;
    })
  ];
}
