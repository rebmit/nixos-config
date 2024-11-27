{ pkgs, lib, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10;
    keyMode = "vi";
    terminal = "tmux-256color";
    historyLimit = 50000;
    plugins = with pkgs.tmuxPlugins; [
      yank
      open
    ];
    extraConfig = ''
      set -g set-clipboard on
      set -g mouse on
      set -g status-right ""
      set -g renumber-windows on
      set -g bell-action none

      # keybind
      bind \; command-prompt
      bind p paste-buffer
      bind C-p choose-buffer

      # pane
      bind k select-pane -U
      bind j select-pane -D
      bind h select-pane -L
      bind l select-pane -R
      bind -r C-k resize-pane -U 5
      bind -r C-j resize-pane -D 5
      bind -r C-h resize-pane -L 5
      bind -r C-l resize-pane -R 5

      # copy mode
      bind Escape copy-mode
      bind -T copy-mode-vi k send -X cursor-up
      bind -T copy-mode-vi K send -N 5 -X cursor-up
      bind -T copy-mode-vi j send -X cursor-down
      bind -T copy-mode-vi J send -N 5 -X cursor-down
      bind -T copy-mode-vi h send -X cursor-left
      bind -T copy-mode-vi H send -N 5 -X cursor-left
      bind -T copy-mode-vi C-h send -X start-of-line
      bind -T copy-mode-vi l send -X cursor-right
      bind -T copy-mode-vi L send -N 5 -X cursor-right
      bind -T copy-mode-vi C-l send -X end-of-line
      bind -T copy-mode-vi v send -X begin-selection

      # window
      bind -r [ previous-window
      bind -r ] next-window
      bind -r C-[ swap-window -d -t -1
      bind -r C-] swap-window -d -t +1
      bind -r - split-window -h -c "#{pane_current_path}"
      bind -r = split-window -v -c "#{pane_current_path}"
      bind C-x kill-window
      bind c new-window -c "#{pane_current_path}"
      bind r command-prompt "rename-window %%"

      # session
      bind q confirm-before -p "kill-session #S? (y/n)" kill-session
      bind R command-prompt "rename-session %%"

      # image preview
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
    '';
  };

  programs.kitty.settings.shell = lib.mkDefault "tmux";
}
