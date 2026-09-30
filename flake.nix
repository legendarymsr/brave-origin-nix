{
  description = "Brave Origin (nightly) browser — packaged for NixOS";

  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    # No `inputs.nixpkgs.follows` here on purpose: nixvim evaluates its module
    # set against its own pinned Nixpkgs (and warns when that is overridden).
    nixvim.url       = "github:nix-community/nixvim";
  };

  outputs = { self, nixpkgs, nixvim }:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};
      brave-origin = pkgs.callPackage ./pkgs/brave-origin.nix {};
    in {
      packages.${system} = {
        brave-origin = brave-origin;
        default      = brave-origin;
        update       = pkgs.callPackage ./update.nix {};
      };
      nixosModules.brave-origin       = import ./modules/nixos.nix    { inherit brave-origin; };
      nixosModules.xfce               = import ./modules/xfce.nix;
      homeModules.brave-origin = import ./modules/home.nix     { inherit brave-origin; };
      homeModules.xfce         = import ./modules/xfce-home.nix;
      homeModules.nixvim       = {
        imports = [ nixvim.homeModules.nixvim ./modules/nixvim.nix ];
      };
      # Backwards-compatible alias (older name for the same modules).
      homeManagerModules = self.homeModules;
    };
}
