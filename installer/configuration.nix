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
# After booting, run: brave-origin-install /dev/sdX
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ── Identity ───────────────────────────────────────────────────────────
  networking.hostName = "brave-origin-installer";
  time.timeZone       = "UTC";
  i18n.defaultLocale  = "en_US.UTF-8";

  # ── Shrink the ISO below GitHub's 2 GB release-asset limit ────────────
  # Remove ZFS modules (~300 MB) and Xorg (~400 MB) — neither needed
  # for a terminal-only installer.
  boot.supportedFilesystems = lib.mkOverride 10 [ "ext4" "vfat" "btrfs" "xfs" "ntfs" ];
  boot.kernelModules        = lib.mkForce [];

  services.xserver.enable = lib.mkForce false;

  # ── Live-environment packages ──────────────────────────────────────────
  # Minimal set — only what the install script needs.
  # brave-origin NOT here; nixos-install fetches it from GitHub.
  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    curl
    (pkgs.writeShellScriptBin "brave-origin-install"
      (builtins.readFile ./brave-origin-install))
  ];

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
