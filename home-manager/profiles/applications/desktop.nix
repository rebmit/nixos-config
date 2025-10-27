{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start block=yes
    (mpv.override {
      scripts = with pkgs.mpvScripts; [
        # keep-sorted start
        modernz
        mpris
        thumbfast
        # keep-sorted end
      ];
    })
    bustle
    dmlive
    evolution
    foliate
    ghostty
    gimp3
    libreoffice-fresh
    loupe
    nautilus
    nheko
    papers
    seahorse
    swappy
    tdesktop
    zotero
    # keep-sorted end
  ];

  preservation.directories = [
    ".zotero"

    ".cache/evolution"
    ".cache/org.gnome.Evolution"
    ".config/dconf"
    ".config/evolution"
    ".config/nheko"
    ".local/share/evolution"
    ".local/share/org.gnome.Evolution"
    ".local/share/nheko"
    ".local/share/TelegramDesktop"

    ".pki/nssdb"

    "Zotero"
  ];
}
