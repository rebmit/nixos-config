set shell := ["bash", "-c"]

[linux]
[group('nix')]
remote name:
  nixos-rebuild switch --flake .#{{name}} --target-host root@{{name}} --verbose --show-trace

[linux]
[group('nix')]
local name:
  nixos-rebuild switch --use-remote-sudo --flake .#{{name}} --verbose --show-trace

[macos]
[group('nix')]
local name:
  darwin-rebuild switch --flake .#{{name}} --verbose --show-trace

[group('nix')]
up:
  nix flake update

[group('nix')]
upp input:
  nix flake update {{input}}

[group('nix')]
history:
  nix profile diff-closures --profile /nix/var/nix/profiles/system

[group('nix')]
repl:
  nix repl -f flake:nixpkgs

[linux]
[group('infra')]
plan:
  tofu -chdir="infra" plan

[linux]
[group('infra')]
apply:
  tofu -chdir="infra" apply

[linux]
[group('infra')]
zone:
  tofu -chdir="infra" output -json | jq -f zones/data.jq > zones/data.json
  cat zones/data.json | jq -f zones/registry.jq > zones/registry.json

[linux]
[group('infra')]
secret name:
  nix eval --raw .#nixosConfigurations.{{name}}.config.sops.opentofuTemplate > test.json
  tofu -chdir="infra" output -json | jq -f test.json > secrets/hosts/opentofu/{{name}}.yaml
  sops --input-type json --output-type yaml --in-place --encrypt secrets/hosts/opentofu/{{name}}.yaml
  rm -i test.json
