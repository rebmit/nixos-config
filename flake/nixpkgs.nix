{ inputs, ... }:
let
  overlays = [
    inputs.rebmit.overlays.default
    inputs.nixpkgs-terraform-providers-bin.overlay

    (_final: prev: {
      mautrix-telegram = prev.mautrix-telegram.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch2 {
            name = "mautrix-telegram-sticker";
            url = "https://github.com/mautrix/telegram/pull/991/commits/0c2764e3194fb4b029598c575945060019bad236.patch";
            hash = "sha256-48QiKByX/XKDoaLPTbsi4rrlu9GwZM26/GoJ12RA2qE=";
          })
        ];
      });
      caddy-rebmit = prev.caddy.withPlugins {
        plugins = [ "github.com/mholt/caddy-l4@v0.0.0-20250829174953-ad3e83c51edb" ];
        hash = "sha256-6X8qGPAlKdPnddtmkgZfWrY62/J91OKFzyGSUbPY+6E=";
      };
    })
  ];
in
{
  perSystem =
    { lib, ... }:
    let
      inherit (lib.lists) elem;
      inherit (lib.strings) getName;
    in
    {
      nixpkgs = {
        config = {
          allowUnfree = false;
          allowUnfreePredicate =
            p:
            elem (getName p) [
              # keep-sorted start
              # keep-sorted end
            ];

          allowNonSource = false;
          allowNonSourcePredicate =
            p:
            elem (getName p) [
              # keep-sorted start
              "Microsoft.AspNetCore.App.Ref"
              "Microsoft.AspNetCore.App.Runtime.linux-arm64"
              "Microsoft.AspNetCore.App.Runtime.linux-x64"
              "Microsoft.AspNetCore.App.Runtime.osx-arm64"
              "Microsoft.AspNetCore.App.Runtime.osx-x64"
              "Microsoft.DotNet.ILCompiler"
              "Microsoft.NET.ILLink.Tasks"
              "Microsoft.NETCore.App.Crossgen2.linux-arm64"
              "Microsoft.NETCore.App.Crossgen2.linux-x64"
              "Microsoft.NETCore.App.Crossgen2.osx-arm64"
              "Microsoft.NETCore.App.Crossgen2.osx-x64"
              "Microsoft.NETCore.App.Host.linux-arm64"
              "Microsoft.NETCore.App.Host.linux-x64"
              "Microsoft.NETCore.App.Host.osx-arm64"
              "Microsoft.NETCore.App.Host.osx-x64"
              "Microsoft.NETCore.App.Ref"
              "Microsoft.NETCore.App.Runtime.Mono.linux-arm64"
              "Microsoft.NETCore.App.Runtime.Mono.linux-x64"
              "Microsoft.NETCore.App.Runtime.Mono.osx-arm64"
              "Microsoft.NETCore.App.Runtime.Mono.osx-x64"
              "Microsoft.NETCore.App.Runtime.linux-arm64"
              "Microsoft.NETCore.App.Runtime.linux-x64"
              "Microsoft.NETCore.App.Runtime.osx-arm64"
              "Microsoft.NETCore.App.Runtime.osx-x64"
              "Microsoft.NETCore.DotNetAppHost"
              "Microsoft.NETCore.DotNetHost"
              "Microsoft.NETCore.DotNetHostPolicy"
              "Microsoft.NETCore.DotNetHostResolver"
              "Newtonsoft.Json"
              "System.Formats.Asn1"
              "System.Reflection.Metadata"
              "System.Text.Json"
              "ant"
              "aspnetcore-runtime"
              "bazel"
              "bazel-hacks"
              "cargo-bootstrap"
              "dart"
              "dotnet-runtime"
              "dotnet-sdk"
              "go"
              "gradle"
              "keycloak"
              "libreoffice"
              "runtime.linux-arm64.Microsoft.DotNet.ILCompiler"
              "runtime.linux-arm64.Microsoft.NETCore.DotNetAppHost"
              "runtime.linux-arm64.Microsoft.NETCore.DotNetHost"
              "runtime.linux-arm64.Microsoft.NETCore.DotNetHostPolicy"
              "runtime.linux-arm64.Microsoft.NETCore.DotNetHostResolver"
              "runtime.linux-arm64.Microsoft.NETCore.ILAsm"
              "runtime.linux-arm64.Microsoft.NETCore.ILDAsm"
              "runtime.linux-x64.Microsoft.DotNet.ILCompiler"
              "runtime.linux-x64.Microsoft.NETCore.DotNetAppHost"
              "runtime.linux-x64.Microsoft.NETCore.DotNetHost"
              "runtime.linux-x64.Microsoft.NETCore.DotNetHostPolicy"
              "runtime.linux-x64.Microsoft.NETCore.DotNetHostResolver"
              "runtime.linux-x64.Microsoft.NETCore.ILAsm"
              "runtime.linux-x64.Microsoft.NETCore.ILDAsm"
              "runtime.osx-arm64.Microsoft.DotNet.ILCompiler"
              "runtime.osx-arm64.Microsoft.NETCore.DotNetAppHost"
              "runtime.osx-arm64.Microsoft.NETCore.DotNetHost"
              "runtime.osx-arm64.Microsoft.NETCore.DotNetHostPolicy"
              "runtime.osx-arm64.Microsoft.NETCore.DotNetHostResolver"
              "runtime.osx-arm64.Microsoft.NETCore.ILAsm"
              "runtime.osx-arm64.Microsoft.NETCore.ILDAsm"
              "runtime.osx-x64.Microsoft.DotNet.ILCompiler"
              "runtime.osx-x64.Microsoft.NETCore.DotNetAppHost"
              "runtime.osx-x64.Microsoft.NETCore.DotNetHost"
              "runtime.osx-x64.Microsoft.NETCore.DotNetHostPolicy"
              "runtime.osx-x64.Microsoft.NETCore.DotNetHostResolver"
              "runtime.osx-x64.Microsoft.NETCore.ILAsm"
              "runtime.osx-x64.Microsoft.NETCore.ILDAsm"
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
