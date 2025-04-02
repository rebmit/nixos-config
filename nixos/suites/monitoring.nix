{ profiles, ... }:
{
  imports = with profiles; [
    # keep-sorted start
    services.prometheus.node-exporter
    # keep-sorted end
  ];
}
