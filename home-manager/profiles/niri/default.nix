# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/d40b75ca0955d2a999b36fa1bd0f8b3a6e061ef3/home-manager/profiles/niri/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.niri;
in
{
  options.programs.niri = {
    browser = lib.mkOption {
      type = with lib.types; listOf str;
      description = ''
        The command of the default browser.
      '';
    };
    terminal = lib.mkOption {
      type = with lib.types; listOf str;
      description = ''
        The command of the default terminal.
      '';
    };
    xwayland = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable xwayland support.
      '';
    };
  };

  config = lib.mkMerge [
    # niri
    {
      programs.niri = {
        package = pkgs.niri;
        settings = {
          input = {
            touchpad = {
              tap = true;
              natural-scroll = true;
              dwt = true;
            };
          };
          layout = {
            gaps = 8;
            center-focused-column = "never";
            preset-column-widths = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
            ];
            default-column-width = {
              proportion = 1.0 / 2.0;
            };
            focus-ring = {
              enable = true;
              width = 4;
              active.color = "#7fc8ff";
              inactive.color = "#505050";
            };
            border = {
              enable = false;
              width = 4;
              active.color = "#ffc87f";
              inactive.color = "#505050";
            };
            struts = { };
          };
          hotkey-overlay = {
            skip-at-startup = true;
          };
          spawn-at-startup = [ ];
          prefer-no-csd = true;
          screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
          animations.enable = true;
          window-rules = [
            {
              geometry-corner-radius =
                let
                  radius = 12.0;
                in
                {
                  bottom-left = radius;
                  bottom-right = radius;
                  top-left = radius;
                  top-right = radius;
                };
              clip-to-geometry = true;
            }
          ];
          binds =
            let
              modMove = "Shift";
              modMonitor = "Ctrl";
              keyUp = "K";
              keyDown = "J";
              keyLeft = "H";
              keyRight = "L";
              directions = {
                left = {
                  keys = [
                    keyLeft
                    "WheelScrollLeft"
                  ];
                  windowTerm = "column";
                };
                down = {
                  keys = lib.singleton keyDown;
                  windowTerm = "window";
                };
                up = {
                  keys = lib.singleton keyUp;
                  windowTerm = "window";
                };
                right = {
                  keys = [
                    keyRight
                    "WheelScrollRight"
                  ];
                  windowTerm = "column";
                };
              };
              workspaceIndices = lib.range 1 9;
              isWheelKey = lib.hasPrefix "Wheel";
              wheelCooldownMs = 100;
              windowBindings = lib.mkMerge (
                lib.concatLists (
                  lib.mapAttrsToList (
                    direction: cfg:
                    (lib.lists.map (
                      key:
                      let
                        cooldown-ms = lib.mkIf (isWheelKey key) wheelCooldownMs;
                      in
                      {
                        "Mod+${key}" = {
                          action."focus-${cfg.windowTerm}-${direction}" = [ ];
                          inherit cooldown-ms;
                        };
                        "Mod+${modMove}+${key}" = {
                          action."move-${cfg.windowTerm}-${direction}" = [ ];
                          inherit cooldown-ms;
                        };
                        "Mod+${modMonitor}+${key}" = {
                          action."focus-monitor-${direction}" = [ ];
                          inherit cooldown-ms;
                        };
                        "Mod+${modMove}+${modMonitor}+${key}" = {
                          action."move-column-to-monitor-${direction}" = [ ];
                          inherit cooldown-ms;
                        };
                      }
                    ) cfg.keys)
                  ) directions
                )
              );
              indexedWorkspaceBindings = lib.mkMerge (
                map (index: {
                  "Mod+${toString index}" = {
                    action.focus-workspace = [ index ];
                  };
                  "Mod+${modMove}+${toString index}" = {
                    action.move-column-to-workspace = [ index ];
                  };
                }) workspaceIndices
              );
              specialBindings = {
                "Mod+W".action.spawn = cfg.browser;
                "Mod+Return".action.spawn = cfg.terminal;
                "Mod+D".action.spawn = [ "fuzzel" ];
                "Mod+M".action.spawn = [ "swaylock" ];
                "Mod+V".action.spawn = [ "cliphist-fuzzel" ];
                "XF86AudioRaiseVolume" = {
                  allow-when-locked = true;
                  action.spawn = [
                    "${pkgs.pulsemixer}/bin/pulsemixer"
                    "--change-volume"
                    "+5"
                  ];
                };
                "XF86AudioLowerVolume" = {
                  allow-when-locked = true;
                  action.spawn = [
                    "${pkgs.pulsemixer}/bin/pulsemixer"
                    "--change-volume"
                    "-5"
                  ];
                };
                "XF86AudioMute" = {
                  allow-when-locked = true;
                  action.spawn = [
                    "${pkgs.pulsemixer}/bin/pulsemixer"
                    "--toggle-mute"
                  ];
                };
                "Mod+P".action.spawn = [
                  "${pkgs.playerctl}/bin/playerctl"
                  "play-pause"
                ];
                "Mod+I".action.spawn = [
                  "${pkgs.playerctl}/bin/playerctl"
                  "previous"
                ];
                "Mod+O".action.spawn = [
                  "${pkgs.playerctl}/bin/playerctl"
                  "next"
                ];
                "Mod+Shift+Q".action.close-window = [ ];
                "Mod+Tab".action.focus-workspace-previous = [ ];
                "Mod+C".action.center-column = [ ];
                "Mod+Comma".action.consume-window-into-column = [ ];
                "Mod+Period".action.expel-window-from-column = [ ];
                "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
                "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
                "Mod+R".action.switch-preset-column-width = [ ];
                "Mod+Shift+R".action.reset-window-height = [ ];
                "Mod+F".action.maximize-column = [ ];
                "Mod+Shift+F".action.fullscreen-window = [ ];
                "Mod+Minus".action.set-column-width = [ "-10%" ];
                "Mod+Equal".action.set-column-width = [ "+10%" ];
                "Mod+Shift+Minus".action.set-window-height = [ "-10%" ];
                "Mod+Shift+Equal".action.set-window-height = [ "+10%" ];
                "Mod+Shift+S".action.screenshot = [ ];
                "Mod+Ctrl+S".action.screenshot-window = [ ];
                "Mod+Shift+E".action.quit = [ ];
              };
            in
            lib.mkMerge [
              windowBindings
              indexedWorkspaceBindings
              specialBindings
            ];
          cursor = {
            theme = config.theme.cursorTheme;
            size = config.theme.cursorSize;
          };
        };
      };

      home.packages = with pkgs; [
        (hiPrio (writeShellApplication {
          name = "wayland-session";
          runtimeInputs = [ cfg.package ];
          text = ''
            niri-session
          '';
        }))

        cfg.package
        wl-clipboard
      ];
    }

    # xdg-desktop-portal
    {
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        config = {
          common = {
            "default" = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };
      };

      home.packages = with pkgs; [
        xdg-utils
      ];
    }

    # xwayland
    (lib.mkIf cfg.xwayland {
      systemd.user.services.xwayland-satellite = {
        Unit = {
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          Requisite = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.xwayland-satellite} :1";
          NotifyAccess = "all";
          StandardOutput = "journal";
          Restart = "on-failure";
        };
      };

      programs.niri.settings.environment = lib.singleton {
        DISPLAY = ":1";
      };
    })
  ];
}
