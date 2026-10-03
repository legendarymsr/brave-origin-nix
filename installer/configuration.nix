{ config, pkgs, lib, modulesPath, brave-origin, ... }:
# Custom NixOS installer ISO — Brave Origin nightly pre-installed.
#
# Build:
#   nix build .#nixosConfigurations.installer.config.system.build.isoImage
#
# The resulting ISO is at:
#   result/iso/brave-origin-installer-*.iso
#
# Write to USB:
#   sudo dd if=result/iso/brave-origin-installer-*.iso \
#            of=/dev/sdX bs=4M status=progress oflag=sync
#
# After booting, run nixos-install with your own configuration.nix, or
# use the templates in /etc/brave-origin-templates/ as a starting point.
{
  imports = [
    # Minimal installer base (no X, small image)
    # Switch to installation-cd-graphical-gnome.nix for a full desktop
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ── Identity ───────────────────────────────────────────────────────────
  networking.hostName = "brave-origin-installer";
  time.timeZone       = "UTC";
  i18n.defaultLocale  = "en_US.UTF-8";

  # ── Brave Origin ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    brave-origin

    # Tiling WM available in the live env
    ratpoison
    xterm

    # Partitioning / install helpers
    parted
    gptfdisk
    git
    curl
    htop

    # Fonts so xterm is legible
    dejavu_fonts

    # So the user can inspect nix flakes from the live env
    nix
  ];

  # ── Xorg (optional graphical session during install) ───────────────────
  services.xserver = {
    enable       = true;
    # Start ratpoison via xinit; the user runs `startx' after logging in.
    # Remove this block if you want a headless installer.
    windowManager.ratpoison.enable = true;
    displayManager.startx.enable   = true;
  };

  # ── Template configs seeded on the ISO ────────────────────────────────
  # Gives the user a ready-made starting point at /etc/brave-origin-templates/.
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

    "brave-origin-templates/configuration.nix".text = ''
      # /etc/nixos/configuration.nix
      # Minimal NixOS system with Brave Origin, Ratpoison, and home-manager.
      # Adjust the FIXME markers before running nixos-install.
      {
        inputs.brave-origin-nix.url = "github:legendarymsr/brave-origin-nix";
      }
    '' + builtins.readFile ./system-template.nix;

    "brave-origin-templates/home.nix".source =
      pkgs.writeText "home-template.nix" (builtins.readFile ./home-template.nix);
  };

  # ── Flake registry entry so the user can reference the channel ─────────
  nix.registry.brave-origin-nix = {
    from = { type = "indirect"; id = "brave-origin-nix"; };
    to   = {
      type  = "github";
      owner = "legendarymsr";
      repo  = "brave-origin-nix";
    };
  };

  # ── ISO metadata ───────────────────────────────────────────────────────
  isoImage = {
    isoName          = "brave-origin-installer.iso";
    makeEfiBootable  = true;
    makeUsbBootable  = true;
    squashfsCompression = "zstd -Xcompression-level 6";
  };
}
