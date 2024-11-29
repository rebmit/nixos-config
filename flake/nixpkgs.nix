{
  inputs,
  ...
}:
let
  overlays = [
    inputs.ranet.overlays.default

    (final: prev: {
      libadwaita = prev.libadwaita.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../patches/libadwaita-without-adwaita-theme.patch
        ];
        doCheck = false;
      });
      # TODO: wait for https://nixpkgs-tracker.ocfox.me/?pr=360101
      xdg-desktop-portal-gnome = prev.xdg-desktop-portal-gnome.overrideAttrs (_old: {
        propagatedUserEnvPkgs = [
          final.nautilus
        ];
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
