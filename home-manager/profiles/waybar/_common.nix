{
  pkgs,
  ...
}:
{
  height = 36;
  layer = "top";
  "niri/window" = {
    format = "{}";
    max-length = 80;
  };
  "wlr/taskbar" = {
    all-outputs = false;
    on-click = "activate";
    on-click-middle = "close";
  };
  tray = {
    icon-size = 18;
    spacing = 10;
  };
  clock = {
    format = "{:%a %b %d %H:%M}";
  };
  pulseaudio = {
    format = "{icon} {volume}% {format_source}";
    format-bluetooth = "󰂯 {volume}% {format_source}";
    format-bluetooth-muted = "󰝟 {volume}% {format_source}";
    format-icons = {
      headphone = "󰋋";
      default = [
        "󰖀"
        "󰕾"
      ];
    };
    format-muted = "󰝟 {volume}% {format_source}";
    format-source = " {volume}%";
    format-source-muted = " {volume}%";
    on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
  };
  "custom/nixos" = {
    format = "";
    interval = "once";
    tooltip = false;
  };
}
