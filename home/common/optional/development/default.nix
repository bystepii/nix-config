# Development utilities I want across all systems
{
  lib,
  pkgs,
  ...
}:
{
  imports = lib.custom.scanPaths ./.;

  home.packages = lib.flatten [
    (lib.attrValues {
      inherit (pkgs)
        # debuggers
        gdb

        # git tools
        act # github workflow runner
        gh # github cli
        glab # gitlab cli

        # nix
        nixpkgs-review

        # networking
        nmap

        # diffing
        delta
        difftastic

        # parsers
        yq-go # parser for Yaml and Toml Files, that mirrors jq

        # serial debugging
        screen

        # standard man pages for linux API
        man-pages
        man-pages-posix
        ;
      inherit (pkgs.unstable)
        devenv # environment manager
        mob # mob programming tool
        ;
    })
  ];

  home.file.".editorconfig".text = ''
    root = true

    [*]
    end_of_line = lf
    insert_final_newline = true
    indent_style = space
    indent_size = 2

    [*.nix]
    indent_style = space
    indent_size = 2

    [*.lua]
    indent_style = space
    indent_size = 2

    [Makefile]
    indent_style = tab
  '';
}
