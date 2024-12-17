{ ... }:
{
  services.caddy.virtualHosts."rebmit.moe".extraConfig = ''
    route /.well-known/matrix/* {
      header Content-Type application/json
      header Access-Control-Allow-Origin *
      respond /.well-known/matrix/server `${
        builtins.toJSON {
          "m.server" = "matrix.rebmit.moe:443";
        }
      }`
      respond /.well-known/matrix/client `${
        builtins.toJSON {
          "m.homeserver" = {
            "base_url" = "https://matrix.rebmit.moe";
          };
        }
      }`
    }
  '';
}
