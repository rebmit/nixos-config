set shell := ["bash", "-c"]

[linux]
[group('nix')]
remote subcommand name:
  nix copy --substitute-on-destination --no-check-sigs --to ssh-ng://root@{{name}} .#nixosConfigurations.{{name}}.config.system.build.toplevel --verbose --show-trace
  nixos-rebuild {{subcommand}} --flake .#{{name}} --target-host root@{{name}} --verbose --show-trace

[linux]
[group('nix')]
local subcommand name *args:
  nixos-rebuild {{subcommand}} --sudo --flake .#{{name}} --verbose --show-trace {{args}}

[macos]
[group('nix')]
local name *args:
  sudo darwin-rebuild switch --flake .#{{name}} --verbose --show-trace {{args}}

[group('nix')]
up *args:
  nix flake update {{args}}

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
