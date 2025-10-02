_:
{
  services.caddy.virtualHosts."net.rebmit.moe".extraConfig = ''
    handle /geofeed {
      root * ${./_root}
      file_server
    }
  '';
}
