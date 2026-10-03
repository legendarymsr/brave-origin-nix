# brave-origin-install — one-command NixOS + Brave Origin installer
#
# Shipped on the live ISO (installer/configuration.nix) and as
# packages.x86_64-linux.brave-origin-install.
#
# Usage (as root, on the live ISO):
#   brave-origin-install /dev/sdX
#   brave-origin-install /dev/nvme0n1
#   brave-origin-install --help
#
# Partition layout:
#   1 GB   EFI   (FAT32, /boot/efi)
#   4 GB   swap
#   rest   /     (root, ext4; holds /nix too)
#
# Disk tools come from runtimeInputs; nixos-generate-config, nixos-install,
# nix, nixos-enter, timedatectl and udevadm come from the live system's PATH.
{ writeShellApplication, gptfdisk, parted, dosfstools, e2fsprogs, util-linux }:

writeShellApplication {
  name = "brave-origin-install";

  runtimeInputs = [ gptfdisk parted dosfstools e2fsprogs util-linux ];

  text = ''
    red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
    green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
    yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
    bold()   { printf '\033[1m%s\033[0m\n'   "$*"; }
    die()    { red "ERROR: $*"; exit 1; }

    usage() { bold "Usage: brave-origin-install /dev/sdX"; }
    case "''${1:-}" in
      -h|--help)
        usage
        echo "  Partitions /dev/sdX (1 GB EFI, 4 GB swap, rest /),"
        echo "  installs NixOS with XFCE + LightDM and Brave Origin. ERASES THE DISK."
        exit 0 ;;
    esac

    [[ $EUID -eq 0 ]] || die "Run as root: sudo brave-origin-install /dev/sdX"

    DISK="''${1:-}"
    [[ -n "$DISK" ]] || { usage; exit 1; }
    [[ -b "$DISK" ]] || die "$DISK is not a block device"

    if [[ "$DISK" =~ nvme|mmcblk ]]; then
      P() { echo "''${DISK}p''${1}"; }
    else
      P() { echo "''${DISK}''${1}"; }
    fi

    EFI="$(P 1)"
    SWAP="$(P 2)"
    ROOT="$(P 3)"

    bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bold " Brave Origin NixOS Installer"
    bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    yellow "  Target disk : $DISK"
    yellow "  Layout:"
    yellow "    $(P 1)  →  1 GB   EFI   (FAT32, /boot/efi)"
    yellow "    $(P 2)  →  4 GB   swap"
    yellow "    $(P 3)  →  rest   /     (root, ext4; holds /nix too)"
    echo
    red    "  ALL DATA ON $DISK WILL BE DESTROYED."
    echo
    read -rp "  Type YES to continue: " confirm
    [[ "$confirm" == "YES" ]] || { echo "Aborted."; exit 0; }

    echo
    read -rp "  Username [user]: " USERNAME
    USERNAME="''${USERNAME:-user}"

    while true; do
      read -rsp "  Password for $USERNAME: " PASSWORD; echo
      read -rsp "  Confirm password: "        CONFIRM;  echo
      [[ "$PASSWORD" == "$CONFIRM" ]] && break
      yellow "  Passwords do not match, try again."
    done

    read -rp "  Hostname [brave-origin]: " HOSTNAME
    HOSTNAME="''${HOSTNAME:-brave-origin}"

    DETECTED_TZ="$(timedatectl show --property=Timezone --value 2>/dev/null || echo UTC)"
    read -rp "  Timezone [$DETECTED_TZ]: " TIMEZONE
    TIMEZONE="''${TIMEZONE:-$DETECTED_TZ}"

    echo
    green "Starting installation…"
    echo

    bold "[ 1/7 ] Partitioning $DISK…"
    # Re-runs: let go of anything a previous attempt left mounted.
    umount -R /mnt 2>/dev/null || true
    swapoff "$SWAP" 2>/dev/null || true
    sgdisk --zap-all "$DISK"
    sgdisk --new=1:0:+1G   --typecode=1:ef00 --change-name=1:"EFI"      "$DISK"
    sgdisk --new=2:0:+4G   --typecode=2:8200 --change-name=2:"swap"     "$DISK"
    # No separate /nix: the installed XFCE system alone is ~4 GB, so the
    # old 4 GB store partition filled up during nixos-install.
    sgdisk --new=3:0:0     --typecode=3:8300 --change-name=3:"NixOS"    "$DISK"
    partprobe "$DISK"
    udevadm settle || sleep 2

    bold "[ 2/7 ] Formatting…"
    mkfs.vfat -F32 -n EFI   "$EFI"
    mkswap    -L   swap      "$SWAP"
    mkfs.ext4 -F -L NixOS    "$ROOT"
    # udev re-probes the new filesystems; until it is done, type
    # autodetection in mount can fail, so wait and name the types.
    udevadm settle || sleep 2

    bold "[ 3/7 ] Mounting…"
    mount -t ext4 "$ROOT"  /mnt
    mkdir -p /mnt/boot/efi
    mount -t vfat "$EFI"   /mnt/boot/efi
    swapon "$SWAP"

    bold "[ 4/7 ] Generating hardware configuration…"
    nixos-generate-config --root /mnt

    bold "[ 5/7 ] Writing system configuration…"
    cat > /mnt/etc/nixos/flake.nix << FLAKE
    {
      description = "Brave Origin NixOS — $HOSTNAME";

      inputs = {
        # Tarball URLs: no api.github.com calls (its anonymous rate limit
        # is easy to hit behind shared or NATed addresses).
        nixpkgs.url          = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
        brave-origin-nix.url = "https://github.com/legendarymsr/brave-origin-nix/archive/master.tar.gz";
        brave-origin-nix.inputs.nixpkgs.follows = "nixpkgs";
      };

      outputs = { self, nixpkgs, brave-origin-nix }:
      {
        nixosConfigurations.system = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hardware-configuration.nix
            brave-origin-nix.nixosModules.brave-origin
            ({ config, pkgs, lib, ... }: {

              boot.loader.systemd-boot.enable      = true;
              boot.loader.efi.canTouchEfiVariables = true;
              # The ESP is mounted at /boot/efi (not the /boot default).
              boot.loader.efi.efiSysMountPoint     = "/boot/efi";

              networking.hostName              = "$HOSTNAME";
              networking.networkmanager.enable = true;

              time.timeZone      = "$TIMEZONE";
              i18n.defaultLocale = "en_US.UTF-8";

              programs.brave-origin.enable = true;

              services.xserver = {
                enable = true;
                desktopManager.xfce.enable    = true;
                displayManager.lightdm.enable = true;
              };

              users.users.$USERNAME = {
                isNormalUser = true;
                extraGroups  = [ "wheel" "networkmanager" "video" "audio" ];
              };

              environment.systemPackages = with pkgs; [
                git curl htop fastfetch
                thunar xfce4-terminal
              ];

              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              system.stateVersion = "25.05";
            })
          ];
        };
      };
    }
    FLAKE

    bold "[ 6/7 ] Running nixos-install (Brave Origin fetched from GitHub)…"
    # Write flake.lock first: if nixos-install has to create it, the
    # path:/mnt/etc/nixos input changes under it ("NAR hash mismatch").
    nix --extra-experimental-features "nix-command flakes" \
      flake lock /mnt/etc/nixos
    nixos-install \
      --flake /mnt/etc/nixos#system \
      --no-root-passwd \
      --option substituters "https://cache.nixos.org" \
      --option trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

    bold "[ 7/7 ] Setting password…"
    echo "$USERNAME:$PASSWORD" | nixos-enter --root /mnt -- chpasswd

    echo
    bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    green " Done! Remove the USB and reboot."
    bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "  reboot"
    echo
    echo "  LightDM login screen → XFCE desktop"
    echo "  Brave Origin is in the applications menu."
    echo
  '';
}
