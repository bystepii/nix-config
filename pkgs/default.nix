{ pkgs, ... }: pkgs.runCommand "dummy" { } "mkdir $out"
