{
  # osConfig,
  # lib,
  ...
}:
{
  services.kanshi = {
    enable = true;
    settings = [
      # # FIXME: Come up with a way to define profiles via config.monitors?
      # {
      #   profile.name = "default";
      #   profile.outputs =
      #     osConfig.monitors
      #     |> lib.mapAttrsToList (
      #       name: value: {
      #         criteria = name;
      #         status = if value.enabled then "enable" else "disabled";
      #         mode = "${lib.toString value.width}x${lib.toString value.height}@${lib.toString value.refreshRate}Hz";
      #         scale = value.scale;
      #         adaptiveSync = value.vrr != 0;
      #         position = "${lib.toString value.x},${lib.toString value.y}";
      #       }
      #     );
      # }
    ];
  };
}
