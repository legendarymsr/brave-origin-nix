# home-template.nix — seeded onto the ISO at /etc/brave-origin-templates/
# Apply with: nix run home-manager -- switch -f home-template.nix
{ config, pkgs, lib, ... }:
# FIXME: wire in brave-origin-nix when using as a flake:
# { config, pkgs, lib, inputs, ... }:
{
  home.username      = "user";       # FIXME: your username
  home.homeDirectory = "/home/user"; # FIXME
  home.stateVersion  = "25.05";

  # ── Brave Origin (home-manager module) ─────────────────────────────
  # Uncomment after adding brave-origin-nix as a flake input:
  #
  # imports = [ inputs.brave-origin-nix.homeModules.brave-origin ];
  # programs.brave-origin = {
  #   enable         = true;
  #   defaultBrowser = true;
  #   extensions     = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ]; # uBlock Origin
  # };

  # ── Emacs ──────────────────────────────────────────────────────────
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs;
  };

  home.file.".config/emacs/init.el".text = ''
    (setq inhibit-startup-message t)
    (menu-bar-mode   -1)
    (tool-bar-mode   -1)
    (scroll-bar-mode -1)
    (setq-default display-line-numbers-type 'relative)
    (global-display-line-numbers-mode 1)
    (setq-default indent-tabs-mode nil tab-width 2)
    (setq backup-directory-alist
          \`((".". ,(expand-file-name "~/.cache/emacs/"))))
  '';

  # ── Shell ───────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    shellAliases = {
      ls  = "ls --color=auto";
      ll  = "ls -lah --color=auto";
      brv = "brave-origin";
    };
  };

  # ── Packages ──────────────────────────────────────────────────────
  home.packages = with pkgs; [
    git
    curl
    htop
  ];

  programs.home-manager.enable = true;
}
