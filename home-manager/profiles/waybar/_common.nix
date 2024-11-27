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
  network = {
    interval = 1;
    format = "{ifname}";
    format-wifi = "󰇚 {bandwidthDownBytes} 󰕒 {bandwidthUpBytes}";
    format-ethernet = "󰇚 {bandwidthDownBytes} 󰕒 {bandwidthUpBytes}";
    format-disconnected = "";
    tooltip-format = "{ifname} via {gwaddr}";
    tooltip-format-wifi = "{essid} {signalStrength}%";
    tooltip-format-ethernet = "{ifname}";
    tooltip-format-disconnected = "disconnected";
    max-length = 40;
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
