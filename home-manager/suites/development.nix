{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    development
    direnv
    git
    # keep-sorted end
  ];
}
