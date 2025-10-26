{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    delta
    development
    direnv
    git
    # keep-sorted end
  ];
}
