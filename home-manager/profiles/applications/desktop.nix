{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # keep-sorted start
    celluloid
    foliate
    libreoffice-fresh
    loupe
    nautilus
    nheko
    papers
    seahorse
    tdesktop
    thunderbird
    virt-manager
    virt-viewer
    zotero-beta
    # keep-sorted end
  ];

  preservation.preserveAt."/persist".directories = [
    ".thunderbird"
    ".zotero"

    ".config/dconf"
    ".config/nheko"

    ".local/share/nheko"
    ".local/share/TelegramDesktop"

    "Zotero"
  ];
}
