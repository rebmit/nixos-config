{
  inputs,
  lib,
  ...
}:
let
  inherit (lib.lists) elem any;
  inherit (lib.strings) getName match;
in
{
  imports = [
    inputs.rebmit.modules.flake.nixpkgs
    inputs.rebmit.modules.flake.nixpkgsAllowedPredicates
  ];

  perSystem = {
    nixpkgs = {
      config = {
        allowNonSource = false;
      };
      overlays = [
        inputs.rebmit.overlays.default
        inputs.nixpkgs-terraform-providers-bin.overlay

        (_final: prev: {
          caddy-rebmit = prev.caddy.withPlugins {
            plugins = [ "github.com/mholt/caddy-l4@v0.0.0-20250829174953-ad3e83c51edb" ];
            hash = "sha256-yiUgpGkP66FqQED8qnvh3C1XKEM4535R56uVuqcffg8=";
          };
          fuzzel = prev.fuzzel.override {
            svgBackend = "librsvg";
          };
          mautrix-telegram = prev.mautrix-telegram.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or [ ]) ++ [
              (prev.fetchpatch2 {
                name = "mautrix-telegram-sticker";
                url = "https://github.com/mautrix/telegram/pull/991/commits/0c2764e3194fb4b029598c575945060019bad236.patch";
                hash = "sha256-48QiKByX/XKDoaLPTbsi4rrlu9GwZM26/GoJ12RA2qE=";
              })
            ];
          });
          qt6Packages = prev.qt6Packages.overrideScope (
            _final': prev': {
              fcitx5-with-addons = prev'.fcitx5-with-addons.override { libsForQt5.fcitx5-qt = null; };
            }
          );
        })
      ];
      allowedPredicates = {
        nonSource =
          p:
          let
            name = getName p;
          in
          elem name [
            # keep-sorted start
            "ant"
            "cargo-bootstrap"
            "dart"
            "dotnet-sdk"
            "go"
            "gradle"
            "libreoffice"
            "rustc-bootstrap"
            "rustc-bootstrap-wrapper"
            "sof-firmware"
            "temurin-bin"
            "utm"
            "zotero"
            # keep-sorted end
          ]
          || (any (pattern: match pattern name != null) [
            "^(runtime\\..*\\.)?Microsoft\\.(AspNetCore|Build|DotNet|NET|NETCore|VisualStudio)\\..*$"
            "^Newtonsoft.Json$"
            "^System.Formats.Asn1$"
            "^System.Reflection.Metadata$"
            "^System.Text.Json$"
          ]);
        insecure =
          p:
          let
            name = getName p;
          in
          elem name [
            # keep-sorted start
            "olm"
            # keep-sorted end
          ];
      };
    };
  };
}
