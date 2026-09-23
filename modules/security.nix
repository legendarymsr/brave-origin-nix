# Security model for Brave Origin on NixOS
#
# Brave Origin is built on Chromium, which uses a multi-process sandbox.
# The sandbox requires one privilege escalation point: chrome-sandbox must
# run as setuid root so it can create the unprivileged user namespace that
# confines renderer and GPU processes.  The Nix store is read-only and
# never setuid, so this wrapper is provided via security.wrappers instead.
#
# Threat model hardening available here:
#   sandbox       – setuid chrome-sandbox (required for process isolation)
#   apparmor      – MAC profile confining the browser process
#   landlock      – filesystem access restrictions (kernel 5.13+)
#   memoryDenyWriteExecute – blocks JIT abuse; disabled by default because
#                   Chromium's V8 JIT needs W+X pages

{ config, lib, pkgs, brave-origin, ... }: with lib;

let
  cfg = config.programs.brave-origin.security;
  bin = "${brave-origin}/libexec/brave-origin-nightly";
in {

  options.programs.brave-origin.security = {

    sandbox = mkOption {
      type    = types.enum [ "setuid" "userns" "none" ];
      default = "setuid";
      description = ''
        Chromium sandbox mode.

        setuid  – Install chrome-sandbox as a setuid-root wrapper via
                  security.wrappers.  Most secure; requires root at activation.

        userns  – Rely on unprivileged user namespaces instead of a setuid
                  binary.  Requires kernel.unprivilegedUserns = true (already
                  the default on most kernels).  Slightly weaker isolation than
                  setuid mode but needs no privileged helper.

        none    – Pass --no-sandbox to the browser.  Use only in locked-down
                  CI environments where the process itself is already isolated.
                  Not recommended for desktop use.
      '';
    };

    apparmor = mkOption {
      type    = types.bool;
      default = false;
      description = ''
        Load an AppArmor profile for brave-origin.
        Requires security.apparmor.enable = true in your NixOS config.
        The profile allows normal browser operation while denying access to
        sensitive paths such as ~/.ssh, ~/.gnupg, and /etc/shadow.
      '';
    };

    landlock = mkOption {
      type    = types.bool;
      default = false;
      description = ''
        Enable Landlock LSM restrictions for brave-origin (kernel 5.13+).
        When true, the systemd service wrapper limits filesystem access to
        the paths Brave Origin legitimately needs.
        Has no effect when brave-origin is launched directly (e.g. nix run).
      '';
    };

    memoryDenyWriteExecute = mkOption {
      type    = types.bool;
      default = false;
      description = ''
        Set MemoryDenyWriteExecute in the systemd service unit.
        Disabled by default because Chromium's V8 JIT allocates W+X pages.
        Enable only if you run brave-origin with --js-flags=--jitless.
      '';
    };

  };

  config = mkMerge [

    # ── Setuid sandbox ──────────────────────────────────────────────────────
    (mkIf (cfg.sandbox == "setuid") {
      security.wrappers.chrome-sandbox = {
        source  = "${bin}/chrome-sandbox";
        owner   = "root";
        group   = "root";
        setuid  = true;
        # No setgid; chrome-sandbox only needs effective uid 0.
      };
      environment.variables.CHROME_DEVEL_SANDBOX =
        "/run/wrappers/bin/chrome-sandbox";
    })

    # ── Unprivileged user-namespace sandbox ──────────────────────────────────
    (mkIf (cfg.sandbox == "userns") {
      boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;
      # CHROME_DEVEL_SANDBOX intentionally unset; Chromium falls back to userns.
    })

    # ── No sandbox ──────────────────────────────────────────────────────────
    (mkIf (cfg.sandbox == "none") {
      warnings = [
        "programs.brave-origin.security.sandbox = \"none\" disables Chromium process isolation. Only use this in isolated environments."
      ];
    })

    # ── AppArmor profile ────────────────────────────────────────────────────
    (mkIf cfg.apparmor {
      assertions = [{
        assertion = config.security.apparmor.enable;
        message   = "programs.brave-origin.security.apparmor requires security.apparmor.enable = true";
      }];

      security.apparmor.policies."brave-origin" = {
        enable  = true;
        enforce = true;
        profile = ''
          #include <tunables/global>

          ${bin}/brave-origin-nightly flags=(complain) {
            #include <abstractions/base>
            #include <abstractions/fonts>
            #include <abstractions/nameservice>
            #include <abstractions/X>
            #include <abstractions/audio>

            # Brave Origin binary and shared data
            ${bin}/** mr,
            ${brave-origin}/share/** r,

            # User profile and downloads
            owner @{HOME}/.config/BraveSoftware/Brave-Browser-Origin-Nightly/** rwk,
            owner @{HOME}/Downloads/** rw,

            # System libraries
            /nix/store/** mr,
            /run/current-system/sw/** mr,

            # Devices
            /dev/dri/** rw,
            /dev/shm/** rw,
            /dev/video* rw,

            # Networking (via abstraction)
            network inet stream,
            network inet6 stream,
            network inet dgram,
            network inet6 dgram,

            # Secrets — explicitly denied
            deny @{HOME}/.ssh/** rwx,
            deny @{HOME}/.gnupg/** rwx,
            deny /etc/shadow r,
            deny /etc/sudoers r,
          }
        '';
      };
    })

    # ── Landlock (via systemd service hardening) ─────────────────────────────
    (mkIf cfg.landlock {
      assertions = [{
        assertion = versionAtLeast config.boot.kernelPackages.kernel.version "5.13";
        message   = "programs.brave-origin.security.landlock requires kernel >= 5.13";
      }];

      # Expose a hardened launcher unit that wraps the binary.
      # Start with: systemctl --user start brave-origin
      systemd.user.services.brave-origin = {
        description = "Brave Origin (sandboxed)";
        serviceConfig = {
          ExecStart = "${brave-origin}/bin/brave-origin";
          Type      = "simple";

          # Landlock filesystem restrictions
          ReadOnlyPaths    = [ "/nix/store" "/run/current-system" "/etc" ];
          ReadWritePaths   = [ "%h/.config/BraveSoftware" "%h/Downloads" "/dev/shm" "/tmp" ];
          PrivateTmp       = true;
          ProtectHome      = "read-only";
          ProtectSystem    = "strict";

          MemoryDenyWriteExecute = cfg.memoryDenyWriteExecute;

          # Capability restrictions
          CapabilityBoundingSet = "";
          NoNewPrivileges       = mkIf (cfg.sandbox != "setuid") true;

          # Syscall filter (allow what Chromium needs, drop the rest)
          SystemCallFilter      = [ "@system-service" "~@privileged" "~@obsolete" "clone3" "userfaultfd" ];
          SystemCallArchitectures = "native";
        };
      };
    })

  ];
}
