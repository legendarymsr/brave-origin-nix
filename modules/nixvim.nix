{ nixpkgs }:
{ config, lib, ... }: with lib;

{
  options.programs.nixvim-simple.enable =
    mkEnableOption "Minimal nixvim — relative numbers and nixd LSP";

  config = mkMerge [
    {
      # This flake makes nixvim follow its nixpkgs (one shared nixpkgs, no
      # second copy). Tell nixvim explicitly which nixpkgs to use, which is the
      # documented way to acknowledge that and silences its
      # "`programs.nixvim.nixpkgs.source` default value has been affected by
      # your flake input `follows`" warning. mkDefault so users can override it.
      programs.nixvim.nixpkgs.source = mkDefault nixpkgs;
    }

    (mkIf config.programs.nixvim-simple.enable {
      programs.nixvim = {
        enable = true;

        opts = {
          number         = true;
          relativenumber = true;
          expandtab      = true;
          shiftwidth     = 2;
          tabstop        = 2;
        };

        plugins.lsp = {
          enable = true;
          servers.nixd.enable = true;
        };
      };
    })
  ];
}
