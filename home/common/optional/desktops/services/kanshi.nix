{
  osConfig,
  lib,
  ...
}:
{
  services.kanshi = {
    enable = true;
    # settings = [
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
    settings = lib.optionals ((lib.length osConfig.monitors) > 0) [
      {
        profile.name = "default";
        profile.outputs = map (m: {
          criteria = m.name;
          status = if m.enabled then "enable" else "disable";
          mode = "${toString m.width}x${toString m.height}@${toString m.refreshRate}Hz";
          scale = m.scale;
          adaptiveSync = m.vrr != 0;
          position = "${toString m.x},${toString m.y}";
        }) osConfig.monitors;
      }
    ];
  };
}
