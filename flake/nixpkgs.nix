{
  inputs,
  ...
}:
let
  overlays = [
    inputs.rebmit.overlays.default
    inputs.enthalpy.overlays.default
    inputs.nixpkgs-terraform-providers-bin.overlay

    (_final: prev: {
      mautrix-telegram = prev.mautrix-telegram.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/mautrix-telegram-sticker.patch
        ];
      });
      libadwaita = prev.libadwaita.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/libadwaita-without-adwaita-theme.patch
        ];
        doCheck = false;
      });
      caddy-rebmit = prev.caddy.withPlugins {
        plugins = [ "github.com/mholt/caddy-l4@v0.0.0-20250102174933-6e5f5e311ead" ];
        hash = "sha256-j7nc+6n5iBqGyc+CM12AdFc/GJ5iA3tJ3MGPgXyqTOg=";
      };
    })
  ];
in
{
  perSystem =
    { lib, ... }:
    {
      nixpkgs = {
        config = {
          allowUnfree = false;
          allowUnfreePredicate =
            p:
            builtins.elem (lib.getName p) [
              # keep-sorted start
              # keep-sorted end
            ];

          allowNonSource = false;
          allowNonSourcePredicate =
            p:
            builtins.elem (lib.getName p) [
              # keep-sorted start
              "ant"
              "cargo-bootstrap"
              "dotnet-sdk"
              "go"
              "keycloak"
              "libreoffice"
              "rustc-bootstrap"
              "rustc-bootstrap-wrapper"
              "sof-firmware"
              "temurin-bin"
              "utm"
              "zotero"
              "zulu-ca-jdk"
              # keep-sorted end
            ];

          allowInsecurePredicate = p: (p.pname or null) == "olm";
        };
        inherit overlays;
      };
    };
}
