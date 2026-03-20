{
  description = "pi-mono";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
    }:
    let
      rev = "v0.59.0";
      version = "0.59.0";

      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          src = pkgs.fetchFromGitHub {
            owner = "badlogic";
            repo = "pi-mono";
            inherit rev;
            hash = "sha256-EOCF/EYJ81HT8APurHK9qjrEIHG9Wsj3f5HO5wd3JEc=";
          };

        in
        rec {
          default = coding-agent;
          coding-agent = pkgs.callPackage ./nix/coding-agent.nix {
            inherit src version;
          };
        }
      );
    };
}
