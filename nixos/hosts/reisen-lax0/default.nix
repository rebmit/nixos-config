{
  suites,
  mylib,
  ...
}:
{
  imports = suites.server ++ (mylib.path.scanPaths ./. "default.nix");

  services.caddy = {
    enable = true;
    virtualHosts."rebmit.moe".extraConfig = ''
      header /.well-known/matrix/* Content-Type application/json
      header /.well-known/matrix/* Access-Control-Allow-Origin *
      respond /.well-known/matrix/server `{"m.server": "matrix.rebmit.moe:443"}`
      respond /.well-known/matrix/client `{"m.homeserver":{"base_url":"https://matrix.rebmit.moe"}}`
    '';
  };

  system.stateVersion = "24.05";
}
