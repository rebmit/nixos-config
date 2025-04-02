{ suites, ... }:
{
  imports = with suites; [
    workstation
    desktop-baseline
    desktop-niri
  ];
}
