{ ... }:
{
  services.caddy.virtualHosts."net.rebmit.moe".extraConfig = ''
    route /geofeed {
      respond /geofeed <<EOF
        2a0e:aa07:e210::/44,AT,,,
        2a0e:aa07:e21c::/48,SG,,,
        EOF 200
    }
  '';
}
