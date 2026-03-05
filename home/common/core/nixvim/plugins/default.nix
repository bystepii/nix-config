{
  lib,
  ...
}:
{
  imports = (lib.custom.scanPaths ./.);

  #   config = lib.mkIf config.nixvim-config.enable {  # don't want to gif on options one level out of here yet
  config = {
    #
    # ========== ui ==========
    #
    nixvim-config.colorschemes.enable = lib.mkDefault true;
    nixvim-config.plugins.colorizer.enable = lib.mkDefault true;
    nixvim-config.plugins.alpha.enable = lib.mkDefault true;
    nixvim-config.plugins.dressing.enable = lib.mkDefault false;
    nixvim-config.plugins.zen-mode.enable = lib.mkDefault true;
    #
    # ========== bars/lines ==========
    #
    nixvim-config.plugins.bufferline.enable = lib.mkDefault false;
    nixvim-config.plugins.lualine.enable = lib.mkDefault true;
    #
    # ========== debug ==========
    #
    nixvim-config.plugins.dap.enable = lib.mkDefault true;
    nixvim-config.plugins.dap-ui.enable = lib.mkDefault true;
    nixvim-config.plugins.dap-virtual-text.enable = lib.mkDefault true; # Shows values dynamically next to code as comments while debugger is running
    nixvim-config.plugins.dap-lldb.enable = lib.mkDefault true; # C, C++, Rust
    nixvim-config.plugins.dap-python.enable = lib.mkDefault true; # Python
    #nixvim-config.plugins.dap-go.enable = lib.mkDefault true; # Golang
    #nixvim-config.plugins.dap-rr.enable = lib.mkDefault true; # Record and replay debugger
    #
    # ========== trees ==========
    #
    nixvim-config.plugins.neo-tree.enable = lib.mkDefault true;
    nixvim-config.plugins.undotree.enable = lib.mkDefault true;
    #
    # ========== git ==========
    #
    nixvim-config.plugins.gitsigns.enable = lib.mkDefault true;
    nixvim-config.plugins.neogit.enable = lib.mkDefault true;
    nixvim-config.plugins.fugitive.enable = lib.mkDefault true;
    #nixvim-config.plugins.lazygit.enable = lib.mkDefault false;
    #
    # ========== completion ==========
    #
    nixvim-config.plugins.cmp.enable = lib.mkDefault false;
    nixvim-config.plugins.copilot.enable = lib.mkDefault false;
    nixvim-config.plugins.nvim-autopairs.enable = lib.mkDefault false;
    #
    # ========== llm ==========
    #
    nixvim-config.plugins.avante.enable = lib.mkDefault false;
    #
    # ========== languages ==========
    #
    # nixvim-config.plugins.treesitter.enable = lib.mkDefault true;

    #
    # ========== lsp ==========
    #
    nixvim-config.plugins.fidget.enable = lib.mkDefault true;
    nixvim-config.plugins.lspconfig.enable = lib.mkDefault true;
    #
    # ========== search ==========
    #
    nixvim-config.plugins.telescope.enable = lib.mkDefault true;
    nixvim-config.plugins.wilder.enable = lib.mkDefault true;
    #
    # ========== sessions ==========
    #
    # NOTE: disabled because it fucks up neo-tree when nvim opens without a file.
    # Also using zellij for sessions so not really needed anymore
    nixvim-config.plugins.auto-session.enable = lib.mkDefault false;
    #
    # ========== utils ==========
    #
    nixvim-config.plugins.markdown-preview.enable = lib.mkDefault true;
    nixvim-config.plugins.todo-comments.enable = lib.mkDefault true;
    nixvim-config.plugins.which-key.enable = lib.mkDefault true;
  };
}
