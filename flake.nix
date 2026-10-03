{
  description = "Brave Origin (nightly) browser — packaged for NixOS";

  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    nixvim.url       = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
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
      nixosModules.brave-origin = import ./modules/nixos.nix { inherit brave-origin; };
      nixosModules.xfce         = import ./modules/xfce.nix;
      homeModules.brave-origin  = import ./modules/home.nix  { inherit brave-origin; };
      homeModules.xfce          = import ./modules/xfce-home.nix;
      homeModules.nixvim        = {
        imports = [ nixvim.homeModules.nixvim (import ./modules/nixvim.nix { inherit nixpkgs; }) ];
      };
      # Backwards-compatible alias (older name for the same modules).
      homeManagerModules = self.homeModules;

      # Live + installer ISO: boots straight into XFCE (LightDM autologin as
      # `nixos`) with Brave Origin ready; `brave-origin-install` installs.
      # Build: nix build .#nixosConfigurations.installer.config.system.build.isoImage
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit brave-origin; };
        modules = [
          self.nixosModules.brave-origin
          self.nixosModules.xfce
          ./installer/configuration.nix
        ];
      };
    };
}
