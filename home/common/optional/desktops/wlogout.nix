{ pkgs, ... }:
{
  programs.wlogout =
    let
      lockAction = "${pkgs.hyprlock}/bin/hyprlock";
    in
    {
      enable = true;
      layout = [
        {
          label = "lock";
          action = lockAction;
          text = "Loc[k]";
          keybind = "k";
        }
        {
          label = "hibernate";
          action = "${lockAction} & systemctl hibernate";
          text = "[H]ibernate";
          keybind = "h";
        }
        {
          label = "suspend";
          action = "${lockAction} & systemctl suspend";
          text = "[S]uspend";
          keybind = "s";
        }
        {
          label = "logout";
          action = "uwsm stop";
          text = "[L]ogout";
          keybind = "l";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutd[o]wn";
          keybind = "o";
        }
        {
          label = "screen off";
          action = "${lockAction} & niri msg action power-off-monitors";
          text = "Screen Of[f]";
          keybind = "f";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "[R]eboot";
          keybind = "r";
        }
      ];
      #TODO(rice):
      style = ''
              * {
                font-family: "FiraMono Nerd Font", sans-serif;
                background-image: none;
                transition: 20ms;
              }
        #      window {
        #        background-color: rgba(24, 24, 37, 0.1);
        #      }
        #      button {
        #        color: #cdd6f4;
        #        font-size: 20px;
        #        background-repeat: no-repeat;
        #        background-position: center;
        #        background-size: 25%;
        #        border-style: solid;
        #        background-color: rgba(24, 24, 37, 0.3); /* Base Background */
        #        border: 3px solid #cdd6f4; /* Text */
        #        box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
        #      }
        #      button:focus,
        #      button:active,
        #      button:hover {
        #        color: #f5c2e7;
        #        background-color: rgba(24, 24, 37, 0.5); /* Slightly Darker Base */
        #        border: 3px solid #f5c2e7; /* Pink */
        #      }
        #      #logout {
        #        margin: 10px;
        #        border-radius: 20px;
        #        background-image: image(url("icons/logout.png"));
        #      }
        #      #suspend {
        #        margin: 10px;
        #        border-radius: 20px;
        #        background-image: image(url("icons/suspend.png"));
        #      }
        #      #shutdown {
        #        margin: 10px;
        #        border-radius: 20px;
        #        background-image: image(url("icons/shutdown.png"));
        #      }
        #      #reboot {
        #        margin: 10px;
        #        border-radius: 20px;
        #        background-image: image(url("icons/reboot.png"));
        #      }
        #      #lock {
        #        margin: 10px;
        #        border-radius: 20px;
        #        background-image: image(url("icons/lock.png"));
        #      }
        #      #hibernate {
        #        margin: 10px;
        #        border-radius: 20px;
        #        background-image: image(url("icons/hibernate.png"));
        #      }
        #    '';
    };
}
