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
  # brave-origin is NOT in the live env — nixos-install fetches it.
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
    (pkgs.writeShellScriptBin "brave-origin-install"
      (builtins.readFile ./brave-origin-install))
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
      Brave Origin NixOS Installer
      =============================

      One command installs everything — partitions, formats, and installs
      NixOS with Brave Origin.  Brave Origin is fetched from GitHub during
      the install, not from this ISO.

      Usage:

        brave-origin-install /dev/sdX

      (Use lsblk to find your disk name before running.)

      The script asks for: username, password, hostname, timezone.
      After it finishes: remove the USB and reboot.
      Log in, then run `startx' to launch Ratpoison.
      Brave Origin: C-t b inside Ratpoison.
    '';

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
