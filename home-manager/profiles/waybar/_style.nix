{
  base00,
  base02,
  base05,
  base07,
  base0A,
  ...
}:
''
  * {
    border: none;
    border-radius: 0;
    font-family: 'RobotoMono Nerd Font', 'sans';
    font-size: 11pt;
    font-weight: bold;
    min-height: 0;
    color: #${base05};
  }

  window#waybar {
    padding: 0pt;
    opacity: 0.95;
    color: #${base05};
    background: #${base00};
    border-bottom: 2pt solid #${base02};
  }

  window#waybar.hidden {
    opacity: 0.0;
  }

  #workspaces button {
    padding: 5pt;
    background: transparent;
    color: #${base05};
    border-bottom: 2pt solid transparent;
  }

  #workspaces button.focused,
  #workspaces button.active {
    background: #${base02};
    border-bottom: 2pt solid #${base07};
  }

  #workspaces button.urgent {
    background: #${base0A};
  }

  #custom-nixos {
    padding-left: 12pt;
    padding-right: 15pt;
  }

  #window {
    padding: 0pt 8pt;
  }

  #clock,
  #tray,
  #network,
  #pulseaudio {
    margin: 0pt 0pt;
    padding: 0pt 8pt;
  }

  #clock,
  #tray,
  #network,
  #pulseaudio {
    border-left: 2pt solid #${base02};
  }
''
