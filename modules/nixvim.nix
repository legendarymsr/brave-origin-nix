{ config, lib, ... }: with lib;

{
  options.programs.nixvim-simple.enable =
    mkEnableOption "Simple nixvim config with relative numbers and Nix LSP";

  config = mkIf config.programs.nixvim-simple.enable {
    programs.nixvim = {
      enable = true;

      opts = {
        number         = true;
        relativenumber = true;
        expandtab      = true;
        shiftwidth     = 2;
        tabstop        = 2;
        scrolloff      = 8;
        wrap           = false;
        ignorecase     = true;
        smartcase      = true;
        termguicolors  = true;
      };

      globals.mapleader = " ";

      colorschemes.catppuccin = {
        enable  = true;
        settings.flavour = "mocha";
      };

      plugins = {
        lsp = {
          enable = true;
          servers.nixd.enable = true;
        };

        cmp = {
          enable = true;
          settings = {
            sources = [
              { name = "nvim_lsp"; }
              { name = "buffer"; }
              { name = "path"; }
            ];
            mapping = {
              "<Tab>"   = "cmp.mapping.select_next_item()";
              "<S-Tab>" = "cmp.mapping.select_prev_item()";
              "<CR>"    = "cmp.mapping.confirm({ select = true })";
            };
          };
        };

        cmp-nvim-lsp.enable = true;
        cmp-buffer.enable   = true;
        cmp-path.enable     = true;

        treesitter = {
          enable  = true;
          settings.highlight.enable = true;
        };

        telescope = {
          enable = true;
          keymaps = {
            "<leader>ff" = "find_files";
            "<leader>fg" = "live_grep";
            "<leader>fb" = "buffers";
          };
        };

        lualine.enable  = true;
        web-devicons.enable = true;
      };

      keymaps = [
        { key = "<leader>e";  action = "<cmd>Ex<cr>";       mode = "n"; }
        { key = "<C-h>";      action = "<C-w>h";            mode = "n"; }
        { key = "<C-j>";      action = "<C-w>j";            mode = "n"; }
        { key = "<C-k>";      action = "<C-w>k";            mode = "n"; }
        { key = "<C-l>";      action = "<C-w>l";            mode = "n"; }
        { key = "<leader>bn"; action = "<cmd>bnext<cr>";    mode = "n"; }
        { key = "<leader>bp"; action = "<cmd>bprevious<cr>"; mode = "n"; }
        { key = "<leader>bd"; action = "<cmd>bdelete<cr>";  mode = "n"; }
      ];
    };
  };
}
