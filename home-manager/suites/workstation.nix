{ suites, ... }:
{
  imports = with suites; [
    baseline
    development
  ];
}
