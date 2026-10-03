# ─────────────────────────────────────────────────────────────────────────────
# docs.nix — brave-origin-nix
#
# Single-file documentation index in Nix style.
# Not imported by the flake; exists as a human-readable reference.
# ─────────────────────────────────────────────────────────────────────────────
{
  # ── Overview ─────────────────────────────────────────────────────────────
  overview = {
    description = "Brave Origin (nightly) browser packaged as a Nix flake.";
    repository  = "https://github.com/legendarymsr/brave-origin-nix";
    upstream    = "https://brave.com/origin/linux/nightly/";
  };

  # ── Files ─────────────────────────────────────────────────────────────────
  files = {
    "flake.nix"           = "Flake definition — packages, nixosModules, homeManagerModules.";
    "pkgs/brave-origin.nix" = "Main package derivation. Fetches the .deb, extracts, patches ELF, wraps binary.";
    "modules/nixos.nix"   = "NixOS module. Installs brave-origin and sets up chrome-sandbox via security.wrappers.";
    "modules/home.nix"    = "home-manager module. Extensions, defaultBrowser, commandLineArgs options.";
    "modules/xfce.nix"    = "NixOS XFCE module. Convenience DE so you don't need a second flake.";
    "modules/xfce-home.nix" = "home-manager XFCE module. Keybindings, theming, Super+B launches Brave Origin.";
    "modules/nixvim.nix"  = "home-manager nixvim module. Minimal: relative numbers + nixd LSP.";
    "update.nix"          = "Version bumper. Run with `nix run .#update` to fetch latest nightly and patch the hash.";
    "security.nix"        = "Security model documentation — sandbox, privileges, provenance, known limitations.";
    "docs.nix"            = "This file.";
    "README.md"           = "Human-readable docs with code blocks.";
    "README.nix"          = "Same docs as a Nix attribute set, because everything is a .nix file.";
    "COPYING"             = "Licensing explanation — why dual GPL-3.0 / MPL-2.0.";
    "LICENSE"             = "GNU General Public License v3.0 (full text).";
    "LICENSE-MPL"         = "Mozilla Public License 2.0 (full text).";
  };

  # ── Usage ─────────────────────────────────────────────────────────────────
  usage = {
    runWithoutInstalling = ''
      nix run github:legendarymsr/brave-origin-nix --no-write-lock-file --refresh
    '';

    update = ''
      nix run .#update
    '';

    homeManager = {
      flakeInput = ''
        inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
      '';

      config = ''
        imports = [ inputs.brave-origin.homeManagerModules.brave-origin ];

        programs.brave-origin = {
          enable          = true;
          defaultBrowser  = true;                               # optional
          extensions      = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ]; # optional
          commandLineArgs = [ "--force-dark-mode" ];            # optional
        };
      '';
    };

    nixos = ''
      imports = [ inputs.brave-origin.nixosModules.brave-origin ];
      programs.brave-origin.enable = true;
    '';

    oneFlake = ''
      {
        inputs = {
          nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
          home-manager.url = "github:nix-community/home-manager";
          brave-origin.url = "github:legendarymsr/brave-origin-nix";
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
                  programs.brave-origin.enable         = true;
                  programs.brave-origin.defaultBrowser  = true;
                  desktop.xfce.enable                  = true;
                  programs.nixvim-simple.enable        = true;
                  home.stateVersion                    = "24.11";
                };
              }
            ];
          };
        };
      }
    '';
  };

  # ── Licensing ─────────────────────────────────────────────────────────────
  licensing = {
    spdx      = "GPL-3.0-or-later OR MPL-2.0";
    copyright = "Copyright (C) 2026 legendarymsr";
    preferred = "GPL-3.0-or-later";

    summary = ''
      This project is dual-licensed under GPL-3.0 and MPL-2.0.
      GPL-3.0 is the preferred and recommended license — strong copyleft,
      ensures modifications stay open. MPL-2.0 is offered alongside it
      because this flake distributes the Brave Origin binary, which is itself
      MPL-2.0. Using both keeps the packaging license consistent with the
      software it wraps without weakening the copyleft guarantee for those
      who want it.
    '';

    whyNotJustGPL = ''
      Brave Browser is MPL-2.0. As a distributor of the Brave Origin binary
      it is reasonable to honour the spirit of Brave's own license by offering
      the packaging under MPL-2.0 as well.
    '';

    whyNotJustMPL = ''
      MPL-2.0 is weak copyleft — it only requires modifications to MPL-licensed
      files to be shared, not the larger work. Someone could fold this flake
      into a proprietary product. GPL-3.0 prevents that.
    '';

    braveBinary = {
      license = "MPL-2.0";
      holder  = "Brave Software, Inc.";
      source  = "https://github.com/brave/brave-browser";
    };
  };

  # ── Security ──────────────────────────────────────────────────────────────
  # See security.nix for the full security model.
  security = {
    sandboxMechanism  = "chrome-sandbox (setuid helper) + Linux namespaces + seccomp-bpf";
    nixosSetup        = "Automatic via security.wrappers in nixosModules.brave-origin";
    standaloneSetup   = "One-time sudo install; falls back to --no-sandbox";
    integrityCheck    = "fetchurl sha256 pin verified at build time";
    selfUpdate        = false;  # /nix/store is read-only; use nix run .#update
  };
}
