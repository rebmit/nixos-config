# Portions of this file are sourced from
# https://github.com/linyinfeng/dotfiles/blob/b618b0fd16fb9c79ab7199ed51c4c0f98a392cea/nixos/profiles/programs/tools/default.nix (MIT License)
{ pkgs, ... }:
let
  delink = pkgs.writeShellApplication {
    name = "delink";
    text = ''
      file="$1"

      if [ ! -L "$file" ]; then
        echo "'$file' is not a symbolic link" >&2
        exit 1
      fi

      target=$(readlink "$file")
      rm -v "$file"
      cp -v "$target" "$file"
      chmod -v u+w "$file"
    '';
  };
in
{
  programs = {
    command-not-found.enable = false;
    git = {
      enable = true;
      lfs.enable = true;
    };
    htop = {
      enable = true;
      settings = {
        show_program_path = 0;
        highlight_base_name = 1;
        hide_userland_threads = true;
      };
    };
  };

  environment.systemPackages =
    with pkgs;
    [
      # keep-sorted start
      attr
      bashInteractive
      binutils
      coreutils-full
      cpio
      diffutils
      fd
      file
      findutils
      gawk
      getconf
      getent
      gnugrep
      gnupatch
      gnused
      gnutar
      jq
      libtree
      nix-melt
      nix-tree
      nix-weather
      openssl
      p7zip
      procps
      psmisc
      ripgrep
      su
      tree
      unar
      unzipNLS
      util-linux
      which
      zip
      zstd
      # keep-sorted end
    ]
    ++ [
      # keep-sorted start
      delink
      # keep-sorted end
    ];

  passthru = {
    inherit delink;
  };
}
