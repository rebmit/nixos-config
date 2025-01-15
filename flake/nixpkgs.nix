{
  inputs,
  ...
}:
let
  overlays = [
    inputs.rebmit.overlays.default
    inputs.nixpkgs-terraform-providers-bin.overlay

    (_final: prev: {
      bird = prev.bird.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/bird-babel-link-quality-estimation.patch
        ];
      });
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
    })
  ];
in
{
  perSystem =
    { config, lib, ... }:
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
              "zotero"
              # keep-sorted end
            ];

          allowInsecurePredicate = p: (p.pname or null) == "olm";
        };
        inherit overlays;
      };
    };
}
