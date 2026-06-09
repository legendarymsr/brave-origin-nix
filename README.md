# brave-origin-nix

Brave Origin (nightly) browser packaged as a Nix flake.

## Run without installing
nix run github:legendarymsr/brave-origin-nix

## home-manager
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
imports = [ inputs.brave-origin.homeManagerModules.brave-origin ];
programs.brave-origin.enable = true;

## NixOS
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
imports = [ inputs.brave-origin.nixosModules.brave-origin ];
programs.brave-origin.enable = true;
