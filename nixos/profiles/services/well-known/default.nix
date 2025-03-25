{ lib, ... }:
let
  inherit (lib.modules) mkBefore;
in
{
  services.caddy.virtualHosts."rebmit.moe".extraConfig = mkBefore ''
    handle_path /.well-known/matrix/* {
      header Content-Type application/json
      header Access-Control-Allow-Origin *
      root * ${./_root/matrix}
      file_server
    }
  '';
}
