# ─────────────────────────────────────────────────────────────────────────────
# docs.nix — brave-origin-nix
#
# Complete documentation for brave-origin-nix in a single Nix file.
# Contains the full source of every file in the repo as string literals.
# Not imported by the flake; exists as a human-readable reference.
# ─────────────────────────────────────────────────────────────────────────────
{
  overview = {
    description = "Brave Origin (nightly) browser packaged as a Nix flake.";
    repository  = "https://github.com/legendarymsr/brave-origin-nix";
    upstream    = "https://brave.com/origin/linux/nightly/";
  };

  # ── Licensing ─────────────────────────────────────────────────────────────
  licensing = {
    spdx      = "GPL-3.0-or-later OR MPL-2.0";
    copyright = "Copyright (C) 2026 legendarymsr";
    preferred = "GPL-3.0-or-later";

    explanation = ''
      brave-origin-nix is dual-licensed under GPL-3.0 and MPL-2.0.
      You may use, modify, and distribute it under either license, at your option.

      GPL-3.0 is the preferred license — strong copyleft, ensures modifications
      cannot be folded into a closed product without sharing them back.

      MPL-2.0 is offered alongside it because this flake distributes the Brave
      Origin binary, which is itself MPL-2.0 (Brave Software, Inc.). Offering
      MPL-2.0 here keeps the packaging license consistent with the software it
      wraps and respects Brave's own license.

      MPL-2.0 is also copyleft, but weaker — it only requires modifications to
      MPL-licensed files to be shared, not the larger work. GPL-3.0 closes that
      gap. If you are redistributing or building on top of this flake, GPL-3.0
      is recommended.
    '';

    braveBinary = {
      license = "MPL-2.0";
      holder  = "Brave Software, Inc.";
      source  = "https://github.com/brave/brave-browser";
    };
  };

  # ── Files ─────────────────────────────────────────────────────────────────

  "flake.nix" = ''
    {
      description = "Brave Origin (nightly) browser — packaged for NixOS";

      inputs = {
        nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
        nixvim.url       = "github:nix-community/nixvim";
        nixvim.inputs.nixpkgs.follows = "nixpkgs";
      };

      outputs = { self, nixpkgs, nixvim }:
        let
          system = "x86_64-linux";
          pkgs   = nixpkgs.legacyPackages.''${system};
          brave-origin = pkgs.callPackage ./pkgs/brave-origin.nix {};
        in {
          packages.''${system} = {
            brave-origin = brave-origin;
            default      = brave-origin;
            update       = pkgs.callPackage ./update.nix {};
            brave-origin-install = pkgs.callPackage ./installer/brave-origin-install.nix {};
          };
          nixosModules.brave-origin       = import ./modules/nixos.nix    { inherit brave-origin; };
          nixosModules.xfce               = import ./modules/xfce.nix;
          homeModules.brave-origin = import ./modules/home.nix     { inherit brave-origin; };
          homeModules.xfce         = import ./modules/xfce-home.nix;
          homeModules.nixvim       = {
            imports = [ nixvim.homeModules.nixvim (import ./modules/nixvim.nix { inherit nixpkgs; }) ];
          };
          # Backwards-compatible alias (older name for the same modules).
          homeManagerModules = self.homeModules;
        };
    }
  '';

  "pkgs/brave-origin.nix" = ''
    { lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, wrapGAppsHook3,
      alsa-lib, at-spi2-atk, cairo, cups, dbus, expat, fontconfig, gdk-pixbuf,
      glib, gtk3, libX11, libXScrnSaver, libxcb, libXcomposite, libXcursor,
      libXdamage, libXext, libXfixes, libXi, libXrandr, libXrender, libXtst,
      libdrm, libgbm, libuuid, libxshmfence, libXinerama, mesa, nspr, nss,
      pango, systemd, xdg-utils }:

    stdenv.mkDerivation rec {
      pname   = "brave-origin";
      version = "1.98.46";

      src = fetchurl {
        url  = "https://github.com/brave/brave-browser/releases/download/v''${version}/brave-origin-nightly_''${version}_amd64.deb";
        hash = "sha256-pkeAfwVNwzPjOHhjSAMTgt2Yf7MOtAacvQz+86NHGIo=";
      };

      nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];

      buildInputs = [
        alsa-lib at-spi2-atk cairo cups dbus expat fontconfig gdk-pixbuf glib gtk3
        libX11 libXScrnSaver libxcb libXcomposite libXcursor libXdamage libXext
        libXfixes libXi libXrandr libXrender libXtst libdrm libgbm libuuid
        libxshmfence libXinerama mesa nspr nss pango systemd
      ];

      autoPatchelfIgnoreMissingDeps = true;
      dontWrapGApps = true;

      unpackPhase = "dpkg-deb --fsys-tarfile $src | tar x --no-same-permissions";

      installPhase = '''
        runHook preInstall
        mkdir -p $out/bin $out/libexec $out/share/applications $out/share/icons
        cp -r opt/brave.com/brave-origin-nightly $out/libexec/
        chmod +x $out/libexec/brave-origin-nightly/brave-origin-nightly
        cp -r usr/share/applications/. $out/share/applications/ 2>/dev/null || true
        cp -r usr/share/icons/.        $out/share/icons/        2>/dev/null || true

        shopt -s nullglob
        rm -f $out/share/applications/brave-origin-nightly.desktop
        for size in 16 24 32 48 64 128 256; do
          install -Dm644 $out/libexec/brave-origin-nightly/product_logo_''${size}_nightly.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/brave-origin.png
        done
        desktopFiles=($out/share/applications/*.desktop)
        for f in "''${desktopFiles[@]}"; do
          substituteInPlace "$f" \
            --replace-quiet "/usr/bin/brave-origin-nightly" "$out/bin/brave-origin" \
            --replace-quiet "brave-origin-nightly" "brave-origin" || true
        done

        makeShellWrapper $out/libexec/brave-origin-nightly/brave-origin-nightly $out/bin/brave-origin \
          --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
          --suffix PATH          : "''${xdg-utils}/bin" \
          --run '''
            if [ -x /run/wrappers/bin/chrome-sandbox ]; then
              export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chrome-sandbox
              SANDBOX_FLAG=""
            else
              echo "brave-origin: warning: setuid sandbox not found; starting with --no-sandbox." >&2
              SANDBOX_FLAG="--no-sandbox"
            fi
          ''' \
          --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations \$SANDBOX_FLAG"
        runHook postInstall
      ''';

      meta = with lib; {
        description      = "Brave Origin — nightly channel";
        homepage         = "https://brave.com/origin/";
        license          = licenses.mpl20;
        platforms        = [ "x86_64-linux" ];
        mainProgram      = "brave-origin";
        sourceProvenance = [ sourceTypes.binaryNativeCode ];
      };
    }
  '';

  "modules/nixos.nix" = ''
    { brave-origin }:
    { config, lib, ... }: with lib; {
      options.programs.brave-origin.enable = mkEnableOption "Brave Origin (nightly) browser";
      config = mkIf config.programs.brave-origin.enable {
        environment.systemPackages = [ brave-origin ];
        security.wrappers.chrome-sandbox = {
          source = "''${brave-origin}/libexec/brave-origin-nightly/chrome-sandbox";
          owner  = "root";
          group  = "root";
          setuid = true;
        };
      };
    }
  '';

  "modules/home.nix" = ''
    { brave-origin }:
    { config, lib, ... }: with lib;
    let
      cfg = config.programs.brave-origin-nightly;
      desktopFile = "com.brave.Origin.nightly.desktop";
    in {
      options.programs.brave-origin-nightly = {
        enable = mkEnableOption "Brave Origin (nightly) browser";

        defaultBrowser = mkOption {
          type    = types.bool;
          default = false;
          description = "Set brave-origin as the default browser for http/https and HTML.";
        };

        extensions = mkOption {
          type    = types.listOf types.str;
          default = [];
          example = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];
          description = "Chrome Web Store extension IDs to install via External Extensions.";
        };

        commandLineArgs = mkOption {
          type    = types.listOf types.str;
          default = [];
          example = [ "--force-dark-mode" "--disable-smooth-scrolling" ];
          description = "Extra command-line flags passed to brave-origin on startup.";
        };
      };

      config = mkIf cfg.enable {
        home.packages = [ brave-origin ];

        xdg.mimeApps = mkIf cfg.defaultBrowser {
          enable = true;
          defaultApplications = {
            "text/html"                      = desktopFile;
            "x-scheme-handler/http"          = desktopFile;
            "x-scheme-handler/https"         = desktopFile;
            "x-scheme-handler/ftp"           = desktopFile;
            "application/xhtml+xml"          = desktopFile;
            "application/x-extension-htm"    = desktopFile;
            "application/x-extension-html"   = desktopFile;
            "application/x-extension-xhtml"  = desktopFile;
            "application/x-extension-xht"    = desktopFile;
          };
        };

        home.file = listToAttrs (map (id: {
          name  = ".config/BraveSoftware/Brave-Origin-Nightly/External Extensions/''${id}.json";
          value.text = builtins.toJSON {
            external_update_url = "https://clients2.google.com/service/update2/crx";
          };
        }) cfg.extensions);

        xdg.desktopEntries = mkIf (cfg.commandLineArgs != []) {
          "com.brave.Origin.nightly" = {
            name       = "Brave Origin";
            exec       = "brave-origin ''${lib.escapeShellArgs cfg.commandLineArgs} %U";
            icon       = "brave-origin";
            comment    = "Brave browser — Origin (nightly) channel";
            categories = [ "Network" "WebBrowser" ];
            mimeType   = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
          };
        };
      };
    }
  '';

  "modules/xfce.nix" = ''
    { config, lib, pkgs, ... }: with lib;

    let cfg = config.desktop.xfce; in {

      options.desktop.xfce = {
        enable = mkEnableOption "XFCE desktop environment";

        displayManager = mkOption {
          type    = types.enum [ "lightdm" "gdm" "sddm" ];
          default = "lightdm";
          description = "Display manager to use with XFCE.";
        };

        extraPlugins = mkOption {
          type    = types.listOf types.package;
          default = [];
          description = "Additional XFCE panel plugins to install.";
        };
      };

      config = mkIf cfg.enable {

        services.xserver = {
          enable = true;
          desktopManager.xfce.enable = true;
        };

        services.xserver.displayManager.lightdm.enable = cfg.displayManager == "lightdm";
        services.displayManager = {
          gdm.enable  = cfg.displayManager == "gdm";
          sddm.enable = cfg.displayManager == "sddm";
        };

        services.libinput.enable = true;

        environment.systemPackages = with pkgs; [
          thunar thunar-volman xfce4-terminal xfce4-taskmanager
          xfce4-pulseaudio-plugin xfce4-whiskermenu-plugin xfce4-notifyd
          xfconf gvfs polkit_gnome
        ] ++ cfg.extraPlugins;

        security.polkit.enable = true;
        systemd.user.services.polkit-gnome = {
          description = "Polkit GNOME authentication agent";
          wantedBy    = [ "graphical-session.target" ];
          wants       = [ "graphical-session.target" ];
          after       = [ "graphical-session.target" ];
          serviceConfig.ExecStart =
            "''${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        };

        services.gvfs.enable    = true;
        services.tumbler.enable = true;
      };
    }
  '';

  "modules/xfce-home.nix" = ''
    { config, lib, pkgs, ... }: with lib;

    let cfg = config.desktop.xfce; in {

      options.desktop.xfce = {
        enable = mkEnableOption "XFCE home-manager integration";

        theme = mkOption {
          type    = types.str;
          default = "Adwaita-dark";
          description = "GTK/XFCE window manager theme name.";
        };

        iconTheme = mkOption {
          type    = types.str;
          default = "hicolor";
          description = "Icon theme name.";
        };

        terminalFont = mkOption {
          type    = types.str;
          default = "Monospace 11";
          description = "Font for xfce4-terminal (Pango font string).";
        };
      };

      config = mkIf cfg.enable {

        gtk = {
          enable = true;
          theme.name     = cfg.theme;
          iconTheme.name = cfg.iconTheme;
          gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
        };

        xfconf.settings = {

          xfwm4 = {
            "general/theme"           = cfg.theme;
            "general/title_font"      = "Sans Bold 9";
            "general/button_layout"   = "O|HMC";
            "general/use_compositing" = true;
            "general/frame_opacity"   = 100;
          };

          xfce4-keyboard-shortcuts = {
            "commands/custom/<Super>b"      = "brave-origin";
            "commands/custom/<Super>e"      = "thunar";
            "commands/custom/<Super>t"      = "xfce4-terminal";
            "commands/custom/<Super>Escape" = "xflock4";
            "commands/custom/<Super>d"      = "xfdesktop --menu";
            "commands/custom/Print"         = "xfce4-screenshooter";
            "commands/custom/<Super>l"      = null;
            "xfwm4/custom/<Super>d"         = null;
            "xfwm4/custom/<Alt>F4"          = "close_window_key";
            "xfwm4/custom/<Super>h"         = "tile_left_key";
            "xfwm4/custom/<Super>l"         = "tile_right_key";
            "xfwm4/custom/<Super>k"         = "maximize_window_key";
            "xfwm4/custom/<Super>j"         = "hide_window_key";
            "xfwm4/custom/<Super>Tab"       = "cycle_windows_key";
            "xfwm4/custom/<Super><Shift>h"  = "move_window_prev_workspace_key";
            "xfwm4/custom/<Super><Shift>l"  = "move_window_next_workspace_key";
          };

          xsettings = {
            "Net/ThemeName"         = cfg.theme;
            "Net/IconThemeName"     = cfg.iconTheme;
            "Gtk/FontName"          = "Sans 10";
            "Gtk/MonospaceFontName" = cfg.terminalFont;
          };

          xfce4-terminal = {
            "font-name"                     = cfg.terminalFont;
            "misc-show-unsafe-paste-dialog" = false;
            "misc-copy-on-select"           = true;
            "scrolling-unlimited"           = true;
          };

          thunar = {
            "last-show-hidden"    = false;
            "misc-single-click"   = false;
            "misc-thumbnail-mode" = "THUNAR_THUMBNAIL_MODE_ALWAYS";
          };
        };
      };
    }
  '';

  "modules/nixvim.nix" = ''
    { nixpkgs }:
    { config, lib, ... }: with lib;

    {
      options.programs.nixvim-simple.enable =
        mkEnableOption "Minimal nixvim — relative numbers and nixd LSP";

      config = mkMerge [
        {
          programs.nixvim.nixpkgs.source = mkDefault nixpkgs;
        }

        (mkIf config.programs.nixvim-simple.enable {
          programs.nixvim = {
            enable = true;

            opts = {
              number         = true;
              relativenumber = true;
              expandtab      = true;
              shiftwidth     = 2;
              tabstop        = 2;
            };

            plugins.lsp = {
              enable = true;
              servers.nixd.enable = true;
            };
          };
        })
      ];
    }
  '';

  "update.nix" = ''
    # Queries the GitHub Releases API for the newest release that ships a
    # brave-origin-nightly .deb, downloads it, computes the SRI hash, and patches
    # pkgs/brave-origin.nix.
    #
    # Usage:  nix run .#update

    { pkgs ? import <nixpkgs> {} }:

    pkgs.writeShellApplication {
      name = "update-brave-origin";
      runtimeInputs = with pkgs; [ curl python3 gnused gnugrep coreutils jq ];
      text = '''
        NIX_FILE="pkgs/brave-origin.nix"
        REPO="brave/brave-browser"
        API_PATH="repos/$REPO/releases?per_page=50"

        current=$(grep -m1 '"'"'version = '"'"' "$NIX_FILE" | grep -oP '"'"'[0-9]+\.[0-9]+\.[0-9]+'"'"')
        echo "Current version: $current"

        if [ -n "''${GITHUB_TOKEN:-}" ]; then
          releases=$(curl -fsSL --max-time 30 \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            "https://api.github.com/$API_PATH")
        elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
          releases=$(gh api "$API_PATH")
        else
          releases=$(curl -fsSL --max-time 30 "https://api.github.com/$API_PATH")
        fi

        latest=$(printf '"'"'%s'"'"' "$releases" | jq -r '"'"'
          .[]
          | select(any(.assets[]?; .name | test("^brave-origin-nightly_[0-9.]+_amd64\\.deb$")))
          | .tag_name'"'"' \
          | grep -oP '"'"'^v?\K[0-9]+\.[0-9]+\.[0-9]+$'"'"' | sort -Vr | head -n1)

        [ "$latest" = "$current" ] && echo "Already up to date ($current)." && exit 0

        url="https://github.com/$REPO/releases/download/v$latest/brave-origin-nightly_''${latest}_amd64.deb"
        echo "New version: $latest — downloading..."
        tmp=$(mktemp); trap '"'"'rm -f "$tmp"'"'"' EXIT
        curl -fsSL --max-time 600 -o "$tmp" "$url"

        hash=$(sha256sum "$tmp" | awk '"'"'{print $1}'"'"' | \
          python3 -c "import sys,base64,binascii; print('"'"'sha256-'"'"' + base64.b64encode(binascii.unhexlify(sys.stdin.read().strip())).decode())")

        sed -i \
          -e "s|version = \"$current\"|version = \"$latest\"|" \
          -e "s|hash = \"sha256-[^\"]*\"|hash = \"$hash\"|" \
          "$NIX_FILE"

        echo "Updated $NIX_FILE to $latest (hash: $hash)"
        echo "  git add $NIX_FILE && git commit -m \"pkgs: bump brave-origin-nightly to $latest\" && git push"
      ''';
    }
  '';

  "security.nix" = ''
    # Security model for brave-origin-nix. Not imported by the flake.
    {
      provenance = {
        sourceType        = "binaryNativeCode";
        upstream          = "https://github.com/brave/brave-browser/releases";
        integrityVerified = true;  # fetchurl checks sha256 at build time
      };

      nixStore = {
        readOnly      = true;
        setuidAllowed = false;
        elf.rpathPinned = true;  # autoPatchelf pins all ELF RPATHs to /nix/store
      };

      sandbox = {
        architecture = "multi-process";
        mechanisms   = [ "namespaces" "seccomp-bpf" "setuid-helper" ];
        setuidHelper = {
          nixosModule = {
            path      = "/run/wrappers/bin/chrome-sandbox";
            managedBy = "security.wrappers";
          };
          standalone = {
            path     = "/run/wrappers/bin/chrome-sandbox";
            fallback = "--no-sandbox";
          };
        };
      };

      privileges = {
        browserProcess.runsAsRoot              = false;
        setuidHelper.dropsPrivilegesBeforeExec = true;
        ambientCapabilities                    = [];
      };

      network = {
        shields       = true;
        httpsOnlyMode = "user-configurable";
        telemetry     = "opt-in";
      };

      updates = {
        selfUpdate     = false;  # /nix/store is read-only
        nixFlakeUpdate = true;   # nix run .#update
      };

      limitations = [
        "Binary not built from source; trust rests on Brave release signing + fetchurl sha256 pin."
        "autoPatchelfIgnoreMissingDeps = true silences missing Qt shim warnings."
        "chrome-sandbox requires privileged setup outside the Nix store (security.wrappers or manual install)."
        "x86_64-linux only."
      ];
    }
  '';
}
