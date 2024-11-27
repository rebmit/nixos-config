{ ... }:
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "ra";
    settings = {
      manager = {
        sort_by = "natural";
        linemode = "size";
      };
      preview = {
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
      };
      open.rules = [
        {
          name = "*/";
          use = [
            "open"
            "edit"
            "reveal"
          ];
        }
        {
          mime = "text/*";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "{image,audio,video}/*";
          use = [
            "open"
            "reveal"
          ];
        }
        {
          mime = "application/{,g}zip";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
          use = [
            "extract"
            "reveal"
          ];
        }
        {
          mime = "application/{json,x-ndjson}";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "*/javascript";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "inode/x-empty";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          name = "*";
          use = [
            "open"
            "reveal"
          ];
        }
      ];
    };
    keymap = {
      manager.prepend_keymap = [
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
