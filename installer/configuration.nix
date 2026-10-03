{ config, pkgs, lib, modulesPath, brave-origin, ... }:
# Custom NixOS installer ISO — Brave Origin nightly pre-installed.
#
# Build:
#   nix build .#nixosConfigurations.installer.config.system.build.isoImage
#
# The resulting ISO is at:
#   result/iso/brave-origin-installer.iso
#
# Write to USB:
#   sudo dd if=result/iso/brave-origin-installer.iso \
#            of=/dev/sdX bs=4M status=progress oflag=sync
#
# After booting, run nixos-install with your own configuration.nix, or
# use the templates in /etc/brave-origin-templates/ as a starting point.
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ── Identity ───────────────────────────────────────────────────────────
  networking.hostName = "brave-origin-installer";
  time.timeZone       = "UTC";
  i18n.defaultLocale  = "en_US.UTF-8";

  # ── Brave Origin + live env tools ─────────────────────────────────────
  environment.systemPackages = with pkgs; [
    brave-origin
    ratpoison
    xterm
    xorg.xsetroot
    parted
    gptfdisk
    git
    curl
    htop
    dejavu_fonts
  ];

  # ── Xorg available in the live env ────────────────────────────────────
  # The user logs in at the TTY, runs `startx' to get Ratpoison.
  # No display manager — keep the image small.
  services.xserver = {
    enable                         = true;
    windowManager.ratpoison.enable = true;
  };
  services.displayManager.defaultSession = lib.mkForce "none+ratpoison";

  # .xinitrc for the root user in the live env
  environment.etc."skel/.xinitrc".text = ''
    #!/bin/sh
    xsetroot -cursor_name left_ptr
    exec ratpoison
  '';

  # ── Template configs seeded on the ISO ────────────────────────────────
  environment.etc = {
    "brave-origin-templates/README".text = ''
      Brave Origin NixOS templates
      =============================

      Files in this directory:

        configuration.nix — NixOS system configuration
                            Copy to /mnt/etc/nixos/configuration.nix and edit.
        home.nix          — home-manager configuration

      Quick install:

        1. Partition:   cfdisk /dev/sdX
        2. Format:      mkfs.ext4 /dev/sdXn
        3. Mount:       mount /dev/sdXn /mnt
        4. Generate:    nixos-generate-config --root /mnt
        5. Edit:        nano /mnt/etc/nixos/configuration.nix
                        (or copy the template and adjust FIXMEs)
        6. Install:     nixos-install
        7. Reboot, then: nix run home-manager -- switch -f ~/home.nix
    '';

    "brave-origin-templates/configuration.nix".text =
      builtins.readFile ./system-template.nix;

    "brave-origin-templates/home.nix".text =
      builtins.readFile ./home-template.nix;
  };

  # ── Flake registry so the user can reference brave-origin-nix ─────────
  nix.registry.brave-origin-nix = {
    from = { type = "indirect"; id = "brave-origin-nix"; };
    to   = { type = "github"; owner = "legendarymsr"; repo = "brave-origin-nix"; };
  };

  # ── ISO metadata ───────────────────────────────────────────────────────
  isoImage = {
    isoName             = lib.mkForce "brave-origin-installer.iso";
    isoBaseName         = lib.mkForce "brave-origin-installer";
    makeEfiBootable     = true;
    makeUsbBootable     = true;
    squashfsCompression = "zstd -Xcompression-level 6";
  };
}
