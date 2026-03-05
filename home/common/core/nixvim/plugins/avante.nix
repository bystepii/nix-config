{ config, lib, ... }:
{
  options = {
    nixvim-config.plugins.avante.enable = lib.mkEnableOption "enables avante module";
  };

  config = lib.mkIf config.nixvim-config.plugins.avante.enable {
    programs.nixvim.plugins = {
      avante = {
        enable = true;
        autoLoad = false;
        settings = {
          diff = {
            autojump = true;
            debug = false;
            list_opener = "copen";
          };
          highlights = {
            diff = {
              current = "DiffText";
              incoming = "DiffAdd";
            };
          };
          hints = {
            enabled = true;
          };
          mappings = {
            # diff = {
            #   both = "cb";
            #   next = "]x";
            #   none = "c0";
            #   ours = "co";
            #   prev = "[x";
            #   theirs = "ct";
            # };
          };
          auto_suggestions_provider = "ollama";
          provider = "gemini";
          providers = {
            ollama = {
              endpoint = "http://127.0.0.1:11434";
              model = "qwen2.5-coder:32b";
              extra_request_body = {
                temperature = 0;
                max_completion_tokens = 4096;
              };
            };
            gemini = {
              extra_request_body = {
                max_tokens = 4096;
                temperature = 0;
              };
              model = "gemini-2.5-pro";
            };
            claude = {
              endpoint = "https://api.anthropic.com";
              extra_request_body = {
                max_tokens = 4096;
                temperature = 0;
              };
              model = "claude-3-5-sonnet-20240620";
            };
          };
          windows = {
            sidebar_header = {
              align = "center";
              rounded = true;
            };
            width = 30;
            wrap = true;
          };
        };
      };
    };
  };
}
