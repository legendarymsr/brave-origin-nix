# README.nix — brave-origin-nix
#
# Brave Origin (nightly) browser packaged as a Nix flake.
# Yes, the README is a .nix file. Everything is a .nix file.
{
  description = "brave-origin-nix";

  updating = {
    description = "Bump to the latest nightly version";
    command     = "nix run .#update";
    effect      = "Finds the latest release, downloads it, recomputes the hash, patches pkgs/brave-origin.nix. Then commit and push.";
  };

  runWithoutInstalling = {
    command = "nix run github:legendarymsr/brave-origin-nix --no-write-lock-file --refresh";
  };

  homeManager = {
    flakeInput = ''inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";'';

    usage = {
      imports        = [ "inputs.brave-origin.homeManagerModules.brave-origin" ];
      enable         = true;
      defaultBrowser = true;          # optional — sets brave-origin as default for http/https/HTML
      extensions     = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];  # optional — force-install by CWS ID
      commandLineArgs = [ "--force-dark-mode" ];                  # optional — extra launch flags
    };

    options = {
      enable          = { type = "bool";            default = false;  description = "Install brave-origin"; };
      defaultBrowser  = { type = "bool";            default = false;  description = "Set as default browser for http/https/HTML"; };
      extensions      = { type = "list of strings"; default = [];     description = "Chrome Web Store extension IDs to force-install"; };
      commandLineArgs = { type = "list of strings"; default = [];     description = "Extra flags passed to the browser on startup"; };
    };
  };

  nixos = {
    flakeInput = ''inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";'';
    imports    = [ "inputs.brave-origin.nixosModules.brave-origin" ];
    enable     = true;
    note       = "The NixOS module sets up the chrome-sandbox setuid wrapper automatically via security.wrappers.";
  };

  xfce = {
    description = ''
      The point of this flake is Brave Origin.
      XFCE is here purely so you don't have to mess with multiple flakes.
      Stock XFCE, nothing fancy, stays out of the way.
      If you already have a desktop just ignore this.
    '';

    keybindings = {
      "Super+b"       = "brave-origin";
      "Super+t"       = "terminal";
      "Super+e"       = "file manager (Thunar)";
      "Super+l"       = "lock screen";
      "Super+h"       = "tile left";
      "Super+l"       = "tile right";
      "Super+k"       = "maximise";
      "Super+j"       = "minimise";
      "Super+Tab"     = "cycle windows";
      "Super+Shift+h" = "move to prev workspace";
      "Super+Shift+l" = "move to next workspace";
      "Print"         = "screenshot";
    };

    oneFlakeSetup = {
      description = "One flake, one nixos-rebuild switch — browser + desktop + editor, nothing else needed.";
      example = {
        inputs = {
          nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
          home-manager.url = "github:nix-community/home-manager";
          brave-origin.url = "github:legendarymsr/brave-origin-nix";
          # nixvim is re-exported by brave-origin — no extra input needed
        };
        nixosModules  = [ "brave-origin.nixosModules.brave-origin" "brave-origin.nixosModules.xfce" ];
        homeModules   = [ "brave-origin.homeManagerModules.brave-origin" "brave-origin.homeManagerModules.xfce" "brave-origin.homeManagerModules.nixvim" ];
        options = {
          "programs.brave-origin.enable"        = true;
          "programs.brave-origin.defaultBrowser" = true;
          "desktop.xfce.enable"                 = true;
          "programs.nixvim-simple.enable"       = true;
        };
      };
    };
  };

  sandboxing = {
    nixosModule  = "Handled automatically via security.wrappers.chrome-sandbox.";
    standaloneRun = {
      description = "brave-origin tries sudo -n to install chrome-sandbox. Falls back to --no-sandbox if unavailable.";
      manualSetup = ''
        sudo install -D -m 4755 -o root -g root \
          "$(nix build github:legendarymsr/brave-origin-nix --no-link --print-out-paths)/libexec/brave-origin-nightly/chrome-sandbox" \
          /run/wrappers/bin/chrome-sandbox
      '';
    };
  };

  textEditor = {
    description  = "Minimal nixvim config. No extra flake input needed — it's re-exported by this flake.";
    import       = "inputs.brave-origin.homeManagerModules.nixvim";
    enable       = ''programs.nixvim-simple.enable = true;'';
    features     = [ "relative numbers" "nixd (Nix LSP)" "nvim-cmp completions" "treesitter" "telescope" "catppuccin mocha" "lualine" ];
    keybindings  = {
      "Space+ff"     = "find files";
      "Space+fg"     = "live grep";
      "Space+fb"     = "buffers";
      "Space+e"      = "file explorer";
      "Ctrl+h/j/k/l" = "navigate splits";
      "Tab"          = "next completion";
      "Shift+Tab"    = "prev completion";
      "Enter"        = "confirm completion";
    };
  };
}
