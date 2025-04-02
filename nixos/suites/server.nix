{ suites, ... }:
{
  imports = with suites; [
    baseline
    network
    backup
    monitoring
  ];
}
