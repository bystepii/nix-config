{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama-rocm;
    acceleration = "rocm";
    loadModels = [
      "qwen2.5-coder:32b"
    ];
  };
}
