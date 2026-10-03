# home-template.nix — seeded onto the ISO at /etc/brave-origin-templates/
# Apply with: nix run home-manager -- switch -f home-template.nix
# This is a standalone home-manager configuration.  NOT imported by the flake.
{ config, pkgs, lib, ... }:
# FIXME: wire in brave-origin-nix when using as a flake:
# { config, pkgs, lib, inputs, ... }:
{
  home.username      = "user";                       # FIXME: your username
  home.homeDirectory = "/home/user";                 # FIXME
  home.stateVersion  = "25.05";                      # FIXME: match your nixpkgs

  # ── Brave Origin (home-manager module) ───────────────────────────────
  # Uncomment after adding brave-origin-nix as a flake input:
  #
  # imports = [ inputs.brave-origin-nix.homeModules.brave-origin ];
  # programs.brave-origin = {
  #   enable          = true;
  #   defaultBrowser  = true;
  #   extensions      = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ]; # uBlock Origin
  #   extraArgs       = [ "--force-dark-mode" ];
  # };

  # ── Ratpoison ─────────────────────────────────────────────────────────
  xsession.windowManager.command = "ratpoison";

  home.file.".ratpoisonrc".text = ''
    # ratpoisonrc — dead simple
    set border 1
    set bargravity ne

    bind b exec brave-origin
    bind e exec emacs
    bind t exec xterm

    bind h focusleft
    bind j focusdown
    bind k focusup
    bind l focusright

    bind H exchangeleft
    bind J exchangedown
    bind K exchangeup
    bind L exchangeright

    bind s hsplit
    bind v vsplit
    bind w remove
    bind Q only

    bind n next
    bind p prev
    bind q quit
    bind r restart
  '';

  # ── Emacs ─────────────────────────────────────────────────────────────
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs-nox;
  };

  home.file.".config/emacs/init.el".text = ''
    ;; dead simple
    (setq inhibit-startup-message t)
    (menu-bar-mode   -1)
    (tool-bar-mode   -1)
    (scroll-bar-mode -1)
    (setq-default
     display-line-numbers-type 'relative)
    (global-display-line-numbers-mode 1)
    (setq-default indent-tabs-mode nil
                  tab-width        2)
    (setq backup-directory-alist
          \`(("." . ,(expand-file-name "~/.cache/emacs/"))))
  '';

  # ── Shell ─────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    shellAliases = {
      ls  = "ls --color=auto";
      ll  = "ls -lah --color=auto";
      brv = "brave-origin";
    };
    initExtra = ''
      # Auto-start X on tty1
      if [[ -z "$DISPLAY" && "$XDG_VTNR" -eq 1 ]]; then
        exec startx
      fi
    '';
  };

  # ── .xinitrc ──────────────────────────────────────────────────────────
  home.file.".xinitrc".text = ''
    #!/bin/sh
    xsetroot -cursor_name left_ptr
    [ -f ~/.Xresources ] && xrdb -merge ~/.Xresources
    exec ratpoison
  '';

  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    xterm
    git
    curl
    htop
    dejavu_fonts
  ];

  programs.home-manager.enable = true;
}
