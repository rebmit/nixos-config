_:
{
  programs.zoxide.enable = true;

  preservation.preserveAt."/persist".directories = [
    ".local/share/zoxide"
  ];
}
