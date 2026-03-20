# pi-mono.nix

Nix flake for [pi](https://github.com/badlogic/pi-mono), a terminal coding agent.

## Why

The official pi-mono repo doesn't ship a `flake.nix`. This exists so Nix users can run pi without dealing with npm/node.

See [#2310](https://github.com/badlogic/pi-mono/issues/2310) for context.

## Run

```sh
nix run github:lukasl-dev/pi-mono.nix
```

## Install (NixOS)

```nix
# flake.nix
{
  inputs.pi-mono.url = "github:lukasl-dev/pi-mono.nix";
  # ...
}

# pi-mono.nix
{ inputs, pkgs, ... }: 
{
  environment.systemPackages = [
    inputs.pi-mono.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent
  ];
}
```

## Build

```sh
nix build .#coding-agent
```
