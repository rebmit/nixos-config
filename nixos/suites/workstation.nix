{ profiles, suites, ... }:
{
  imports =
    with suites;
    [
      baseline
      network
      desktop
      backup
    ]
    ++ (with profiles; [
      security.hardware-keys
    ]);
}
