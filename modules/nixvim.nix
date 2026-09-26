{ config, lib, ... }: with lib;

{
  options.programs.nixvim-simple.enable =
    mkEnableOption "Minimal nixvim — relative numbers and nixd LSP";

  config = mkIf config.programs.nixvim-simple.enable {
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
  };
}
