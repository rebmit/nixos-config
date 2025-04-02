{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    services.restic
    # keep-sorted end
  ];
}
