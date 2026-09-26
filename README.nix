# ─────────────────────────────────────────────────────────────────────────────
# README.nix — brave-origin-nix
#
# Brave Origin (nightly) browser packaged as a Nix flake.
# Yes, the README is a .nix file. Everything is a .nix file.
# ─────────────────────────────────────────────────────────────────────────────
{
  # ── Updating ─────────────────────────────────────────────────────────────
  # Bump to the latest nightly. Patches pkgs/brave-origin.nix then commit and push.
  update = ''
    nix run .#update
  '';

  # ─────────────────────────────────────────────────────────────────────────
  # ── Run without installing ───────────────────────────────────────────────
  run = ''
    nix run github:legendarymsr/brave-origin-nix --no-write-lock-file --refresh
  '';

  # ─────────────────────────────────────────────────────────────────────────
  # ── home-manager ─────────────────────────────────────────────────────────
  homeManager = {
    # Add to flake inputs:
    input = ''
      inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
    '';

    # Add to home-manager configuration:
    config = ''
      imports = [ inputs.brave-origin.homeManagerModules.brave-origin ];

      programs.brave-origin = {
        enable          = true;
        defaultBrowser  = true;                              # optional
        extensions      = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ]; # optional — CWS ID
        commandLineArgs = [ "--force-dark-mode" ];           # optional
      };
    '';

    options = {
      enable          = { type = "bool";            default = false; description = "Install brave-origin"; };
      defaultBrowser  = { type = "bool";            default = false; description = "Set as default browser for http/https/HTML"; };
      extensions      = { type = "list of strings"; default = [];    description = "Chrome Web Store extension IDs to force-install"; };
      commandLineArgs = { type = "list of strings"; default = [];    description = "Extra flags passed to the browser on startup"; };
    };
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ── NixOS ────────────────────────────────────────────────────────────────
  # Sets up the chrome-sandbox setuid wrapper automatically via security.wrappers.
  nixos = ''
    inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";

    imports = [ inputs.brave-origin.nixosModules.brave-origin ];
    programs.brave-origin.enable = true;
  '';

  # ─────────────────────────────────────────────────────────────────────────
  # ── XFCE ─────────────────────────────────────────────────────────────────
  # The point of this flake is Brave Origin. XFCE is here purely so you don't
  # have to mess with multiple flakes. Stock XFCE, stays out of the way.
  # If you already have a desktop just ignore this.
  xfce = {
    keybindings = {
      "Super+b"       = "brave-origin";
      "Super+t"       = "terminal";
      "Super+e"       = "file manager (Thunar)";
      "Super+Shift+l" = "lock screen";
      "Super+h"       = "tile left";
      "Super+l"       = "tile right";
      "Super+k"       = "maximise";
      "Super+j"       = "minimise";
      "Super+Tab"     = "cycle windows";
      "Super+Shift+h" = "move to prev workspace";
      "Super+Shift+l" = "move to next workspace";
      "Print"         = "screenshot";
    };

    # One flake, one nixos-rebuild switch — browser + desktop + editor.
    oneFlakeExample = ''
      {
        inputs = {
          nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
          home-manager.url = "github:nix-community/home-manager";
          brave-origin.url = "github:legendarymsr/brave-origin-nix";
          # nixvim is re-exported by brave-origin — no extra input needed
        };

        outputs = { nixpkgs, home-manager, brave-origin, ... }: {
          nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              ./hardware-configuration.nix
              brave-origin.nixosModules.brave-origin
              brave-origin.nixosModules.xfce
              home-manager.nixosModules.home-manager
              {
                programs.brave-origin.enable = true;
                desktop.xfce.enable          = true;

                home-manager.users.youruser = {
                  imports = [
                    brave-origin.homeManagerModules.brave-origin
                    brave-origin.homeManagerModules.xfce
                    brave-origin.homeManagerModules.nixvim
                  ];
                  programs.brave-origin.enable        = true;
                  programs.brave-origin.defaultBrowser = true;
                  desktop.xfce.enable                 = true;
                  programs.nixvim-simple.enable       = true;
                  home.stateVersion                   = "24.11";
                };
              }
            ];
          };
        };
      }
    '';
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ── Sandboxing ────────────────────────────────────────────────────────────
  # NixOS module handles this automatically via security.wrappers.
  # Standalone nix run: tries sudo -n first, falls back to --no-sandbox.
  # Manual one-time setup:
  sandboxing.manualSetup = ''
    sudo install -D -m 4755 -o root -g root \
      "$(nix build github:legendarymsr/brave-origin-nix --no-link --print-out-paths)/libexec/brave-origin-nightly/chrome-sandbox" \
      /run/wrappers/bin/chrome-sandbox
  '';

  # ─────────────────────────────────────────────────────────────────────────
  # ── Text editor ───────────────────────────────────────────────────────────
  # Minimal nixvim — no extra flake input needed, re-exported by this flake.
  textEditor = {
    enable = ''
      imports = [ inputs.brave-origin.homeManagerModules.nixvim ];
      programs.nixvim-simple.enable = true;
    '';

    features    = [ "relative numbers" "nixd (Nix LSP)" "nvim-cmp completions" "treesitter" "telescope" "catppuccin mocha" "lualine" ];
    keybindings = {
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
  # ─────────────────────────────────────────────────────────────────────────
}
