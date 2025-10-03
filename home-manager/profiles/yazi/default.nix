_: {
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "ra";
    settings = {
      mgr = {
        sort_by = "natural";
        linemode = "size";
      };
      preview = {
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
      };
      opener = {
        drag = [
          {
            run = "wl-copy -t text/uri-list file://$(realpath \"$1\")";
            desc = "Drag";
          }
        ];
      };
      open.rules = [
        {
          name = "*/";
          use = [
            "open"
            "edit"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "text/*";
          use = [
            "edit"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "{image,audio,video}/*";
          use = [
            "open"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "application/{,g}zip";
          use = [
            "extract"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
          use = [
            "extract"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "application/{json,x-ndjson}";
          use = [
            "edit"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "*/javascript";
          use = [
            "edit"
            "drag"
            "reveal"
          ];
        }
        {
          mime = "inode/x-empty";
          use = [
            "edit"
            "drag"
            "reveal"
          ];
        }
        {
          name = "*";
          use = [
            "open"
            "drag"
            "reveal"
          ];
        }
      ];
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = [ "J" ];
          run = "arrow 5";
        }
        {
          on = [ "K" ];
          run = "arrow -5";
        }
        {
          on = [ "<C-j>" ];
          run = "seek 5";
        }
        {
          on = [ "<C-k>" ];
          run = "seek -5";
        }
      ];
      input.prepend_keymap = [
        {
          on = [ "H" ];
          run = "move -5";
        }
        {
          on = [ "L" ];
          run = "move 5";
        }
      ];
    };
  };
}
