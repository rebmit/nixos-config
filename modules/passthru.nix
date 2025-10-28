{ lib, ... }:
let
  inherit (lib.options) mkOption;
in
{
  options.passthru = mkOption {
    visible = false;
    description = ''
      This attribute set will be exported as a system attribute.
      You can put whatever you want here.
    '';
  };
}
