{ config, pkgs, lib, modulesPath, brave-origin, ... }:
# Brave Origin NixOS live + installer ISO.
#
# Boots straight into XFCE (LightDM autologin as `nixos`, no password) with
# Brave Origin nightly installed system-wide (setuid chrome-sandbox via
# nixosModules.brave-origin) and opened on login.  The desktop comes from
# this flake's own nixosModules.xfce; both modules are added in flake.nix.
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
# To install from the live desktop, open a terminal and run:
#   sudo brave-origin-install /dev/sdX
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # ── Identity ───────────────────────────────────────────────────────────
  networking.hostName = "brave-origin-installer";
  time.timeZone       = "UTC";
  i18n.defaultLocale  = "en_US.UTF-8";

  # ── Live desktop: XFCE from nixosModules.xfce ──────────────────────
  desktop.xfce.enable = true;               # LightDM is the module default
  # No idle screen lock on the live session (it would ask for the live
  # user's empty password).
  services.xserver.desktopManager.xfce.enableScreensaver = false;
  services.displayManager = {
    defaultSession     = "xfce";
    autoLogin.enable   = true;
    autoLogin.user     = "nixos";           # the live user from installation-cd-base
  };

  # installation-cd-minimal pulls in profiles/minimal.nix, which turns off
  # the XDG bits a desktop needs (icons, MIME, autostart) — turn them back on.
  xdg.autostart.enable = true;
  xdg.icons.enable     = true;
  xdg.mime.enable      = true;
  xdg.sounds.enable    = true;
  services.udisks2.enable = true;           # Thunar volume management
  fonts.enableDefaultPackages = true;

  # ── Brave Origin (nixosModules.brave-origin) ──────────────────────────
  programs.brave-origin.enable = true;      # package + setuid chrome-sandbox

  # Open Brave Origin when the live session starts.  The live user is
  # autologged in, so there is no login password to unlock a keyring with;
  # --password-store=basic skips the "choose password for new keyring" prompt.
  environment.etc."xdg/autostart/brave-origin.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Brave Origin
    Exec=${brave-origin}/bin/brave-origin --password-store=basic --start-maximized
    Icon=brave-origin
    X-GNOME-Autostart-enabled=true
  '';

  # ── Keep the ISO small enough for a GitHub release asset (< 2 GiB) ───
  # No ZFS on the live medium (~300 MB); it is fetched by nixos-install if
  # the installed system wants it.
  boot.supportedFilesystems = lib.mkOverride 10 [ "ext4" "vfat" "btrfs" "xfs" "ntfs" ];
  boot.kernelModules        = lib.mkForce [];

  # Desktop extras that are not worth ~1 GB on a live medium:
  services.speechd.enable  = false;                # speech-dispatcher + mbrola voices + python
  services.orca.enable     = false;
  environment.xfce.excludePackages = [ pkgs.parole ];  # media player → gst-plugins-bad
  services.tumbler.enable  = lib.mkForce false;    # thumbnailer → libgepub → webkitgtk
  xdg.portal.extraPortals  = lib.mkForce [ pkgs.xdg-desktop-portal-gtk ];  # not xapp → mate-panel
  # No copy of nixpkgs on the ISO (registry / NIX_PATH / channel): the
  # installer builds the target from the flake on GitHub anyway.
  nixpkgs.flake.setFlakeRegistry = false;
  nixpkgs.flake.setNixPath       = false;
  system.installer.channel.enable = false;

  # ── Live-environment packages ──────────────────────────────────────────
  # Brave Origin comes from programs.brave-origin above; XFCE apps from
  # nixosModules.xfce.
  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    curl
    fastfetch
    (pkgs.callPackage ./brave-origin-install.nix {})
  ];

  # ── Template configs seeded on the ISO ────────────────────────────────
  environment.etc = {
    "brave-origin-templates/README".text = ''
      Brave Origin NixOS Installer
      =============================

      This ISO is a live XFCE desktop with Brave Origin (nightly).
      One command installs everything — partitions, formats, and installs
      NixOS with XFCE + LightDM and Brave Origin.

      Usage (in a terminal):

        sudo brave-origin-install /dev/sdX

      (Use lsblk to find your disk name before running.)

      The script asks for: username, password, hostname, timezone.
      After it finishes: remove the USB and reboot.
      LightDM login screen → XFCE desktop, Brave Origin in the menu.
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
  image.fileName = lib.mkForce "brave-origin-installer.iso";
  image.baseName = lib.mkForce "brave-origin-installer";
  isoImage = {
    makeEfiBootable     = true;
    makeUsbBootable     = true;
    squashfsCompression = "xz -Xdict-size 100% -Xbcj x86";
  };
}
