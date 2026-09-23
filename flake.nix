{
  description = "Brave Origin (nightly) browser — packaged for NixOS";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
      brave-origin = pkgs.callPackage ./pkgs/brave-origin.nix {};
    in {
      packages.${system} = {
        brave-origin = brave-origin;
        default      = brave-origin;
      };
      nixosModules.brave-origin       = import ./modules/nixos.nix    { inherit brave-origin; };
      nixosModules.xfce               = import ./modules/xfce.nix;
      homeManagerModules.brave-origin = import ./modules/home.nix    { inherit brave-origin; };
      homeManagerModules.xfce         = import ./modules/xfce-home.nix;
    };
}
