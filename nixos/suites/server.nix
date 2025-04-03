{
  profiles,
  suites,
  lib,
  hostData,
  ...
}:
let
  inherit (lib.lists) elem optionals;

  inherit (hostData) labels;
in
{
  imports =
    with suites;
    [
      baseline
      network
      backup
      monitoring
    ]
    ++ optionals (elem "dns/primary" labels) [
      profiles.services.knot.primary
    ]
    ++ optionals (elem "dns/secondary" labels) [
      profiles.services.knot.secondary
    ]
    ++ optionals (elem "bgp/vultr" labels) [
      profiles.services.bgp.vultr
    ];
}
