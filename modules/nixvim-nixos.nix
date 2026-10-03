{ nixpkgs }:
{ pkgs, lib, ... }:
# System-wide Nixvim (NixOS module; flake.nix adds nixvim.nixosModules.nixvim).
# Tokyo Night, vi defaults, line numbers, tree-sitter highlighting for Nix
# and a few small grammars.  Every value is a default, so a system config
# can override any of it under programs.nixvim.
with lib;
{
  programs.nixvim = {
    # nixvim follows this flake's nixpkgs (one shared copy); saying so
    # explicitly silences its "default value has been affected by your
    # flake input `follows`" warning.
    nixpkgs.source = mkDefault nixpkgs;

    enable        = mkDefault true;
    defaultEditor = mkDefault true;          # EDITOR=nvim
    viAlias       = mkDefault true;
    vimAlias      = mkDefault true;
    # No Python/Ruby/Perl/Node remote-plugin hosts (~250 MB, unused here).
    withPython3   = mkDefault false;
    withRuby      = mkDefault false;
    withPerl      = mkDefault false;
    withNodeJs    = mkDefault false;

    colorschemes.tokyonight = {
      enable         = mkDefault true;
      settings.style = mkDefault "night";
    };

    opts = {
      number         = mkDefault true;
      relativenumber = mkDefault true;
      termguicolors  = mkDefault true;
      expandtab      = mkDefault true;
      shiftwidth     = mkDefault 2;
      tabstop        = mkDefault 2;
      smartindent    = mkDefault true;
      ignorecase     = mkDefault true;
      smartcase      = mkDefault true;
      cursorline     = mkDefault true;
      scrolloff      = mkDefault 4;
      signcolumn     = mkDefault "yes";
      mouse          = mkDefault "a";
    };

    plugins.treesitter = {
      enable = mkDefault true;
      settings.highlight.enable = mkDefault true;
      # Only small grammars, not all of them (~1 GB).
      grammarPackages = mkDefault (with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        nix bash lua vim vimdoc markdown
      ]);
    };
  };
}
