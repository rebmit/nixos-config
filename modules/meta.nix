{ inputs, ... }:
{
  imports = [ inputs.rebmit.modules.flake.meta ];

  flake.meta.uri = "github:rebmit/nixos-config";
}
