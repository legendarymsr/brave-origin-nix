{ config, pkgs, lib, modulesPath, brave-origin, ... }:
# Custom NixOS installer ISO — Brave Origin channel pre-configured.
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

  # ── Shrink the ISO below GitHub's 2 GB release-asset limit ────────────
  # ZFS kernel modules alone add ~300 MB; we don't need them for install.
  boot.supportedFilesystems = lib.mkOverride 10 [ "ext4" "vfat" "btrfs" "xfs" "ntfs" ];
  boot.kernelModules        = lib.mkForce [];

  # ── Live-environment packages ──────────────────────────────────────────
  # brave-origin is NOT included in the live env — it gets installed on the
  # target system by nixos-install.  Keeping it out saves ~400 MB on the ISO.
  environment.systemPackages = with pkgs; [
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
  services.xserver = {
    enable                         = true;
    windowManager.ratpoison.enable = true;
  };

  # .xinitrc for the root user: startx → ratpoison
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

        configuration.nix — flake.nix for the target system
                            (rename it to flake.nix when you copy it)
        home.nix          — home-manager configuration

      Brave Origin and all packages are fetched from the internet during
      nixos-install — nothing heavy lives on this ISO.

      Quick install:

        1. Partition:   cfdisk /dev/sdX
        2. Format root: mkfs.ext4 /dev/sdX2
                        (mkfs.vfat /dev/sdX1 for EFI)
        3. Mount:       mount /dev/sdX2 /mnt
                        mkdir -p /mnt/boot/efi
                        mount /dev/sdX1 /mnt/boot/efi
        4. Generate:    nixos-generate-config --root /mnt
        5. Copy template:
                        cp /etc/brave-origin-templates/configuration.nix \
                           /mnt/etc/nixos/flake.nix
                        nano /mnt/etc/nixos/flake.nix  (fill in FIXMEs)
        6. Install:     nixos-install --flake /mnt/etc/nixos#system
           (brave-origin is downloaded from GitHub during this step)
        7. Reboot, then apply home config:
                        nix run home-manager -- switch -f ~/home.nix
    '';

    "brave-origin-templates/configuration.nix".text =
      builtins.readFile ./system-template.nix;

    "brave-origin-templates/home.nix".text =
      builtins.readFile ./home-template.nix;
  };

  # ── Flake registry so users can reference brave-origin-nix ────────────
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
