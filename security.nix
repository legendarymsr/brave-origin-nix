# security.nix — Security model for brave-origin-nix
#
# This file documents the security properties of this package in Nix style.
# It is not imported by the flake; it exists as a human-readable reference.
{
  # ── Package provenance ────────────────────────────────────────────────────
  provenance = {
    # Official upstream binary, fetched by content hash.
    # No source compilation; the .deb is taken as-is from Brave's GitHub.
    sourceType = "binaryNativeCode";
    upstream   = "https://github.com/brave/brave-browser/releases";
    integrityVerified = true;  # fetchurl checks sha256 at build time
  };

  # ── Nix store guarantees ──────────────────────────────────────────────────
  nixStore = {
    # All store paths are read-only and world-readable.
    # No file in /nix/store can be setuid or setgid.
    readOnly  = true;
    setuidAllowed = false;

    # autoPatchelf rewrites ELF RPATH entries to point at pinned store libs.
    # The browser cannot load arbitrary system libraries at runtime.
    elf.rpathPinned = true;
  };

  # ── Chromium process sandbox ──────────────────────────────────────────────
  sandbox = {
    # Chromium splits work across privilege-separated processes:
    #   browser  – orchestrator, trusted, runs as the user
    #   renderer – one per tab/iframe, untrusted, sandboxed
    #   gpu      – GPU command buffer, sandboxed
    #   utility  – network/storage/audio, sandboxed
    architecture = "multi-process";

    # Renderers and GPU processes are confined by a combination of:
    #   - Linux namespaces (user, pid, net, ipc)
    #   - seccomp-bpf syscall filter
    #   - (optionally) a setuid helper for namespace setup
    mechanisms = [ "namespaces" "seccomp-bpf" "setuid-helper" ];

    # chrome-sandbox is the setuid helper. It cannot live in /nix/store
    # because the store forbids setuid bits. Two supported placements:
    setuidHelper = {
      nixosModule = {
        # When using nixosModules.brave-origin the helper is installed via
        # security.wrappers, which places a setuid-root copy at:
        path = "/run/wrappers/bin/chrome-sandbox";
        # and sets CHROME_DEVEL_SANDBOX automatically.
        managedBy = "security.wrappers";
        requiresSudo = false;
      };

      standalone = {
        # When running via `nix run` the wrapper script attempts a one-time
        # non-interactive sudo install, then sets CHROME_DEVEL_SANDBOX.
        # Falls back to --no-sandbox if sudo is unavailable.
        path = "/run/wrappers/bin/chrome-sandbox";
        fallback = "--no-sandbox";
        requiresSudo = true;  # one-time; cached credentials suffice
      };
    };
  };

  # ── Runtime privilege surface ─────────────────────────────────────────────
  privileges = {
    # The browser process itself runs with no elevated privileges.
    browserProcess.runsAsRoot = false;

    # chrome-sandbox performs the privileged namespace setup, then drops
    # to the calling user before execing the sandboxed child.
    setuidHelper.dropsPrivilegesBeforeExec = true;

    # No ambient capabilities are requested or retained.
    ambientCapabilities = [];
  };

  # ── Network ───────────────────────────────────────────────────────────────
  network = {
    # Brave Origin includes a built-in ad/tracker blocker (Brave Shields).
    shields = true;

    # HTTPS-only mode is available but must be enabled by the user.
    httpsOnlyMode = "user-configurable";

    # Brave Rewards / BAT telemetry is opt-in.
    telemetry = "opt-in";
  };

  # ── Updates ───────────────────────────────────────────────────────────────
  updates = {
    # The packaged binary may try to self-update. Under Nix this cannot
    # succeed because /nix/store is read-only. Users must re-run:
    #   nix flake update && nix run github:legendarymsr/brave-origin-nix
    selfUpdate = false;
    nixFlakeUpdate = true;
  };

  # ── Known limitations ─────────────────────────────────────────────────────
  limitations = [
    "Binary is not built from source; supply-chain trust rests on Brave's release signing and the fetchurl sha256 pin."
    "autoPatchelfIgnoreMissingDeps = true silences missing Qt shim warnings; Qt-based file dialogs may fall back gracefully."
    "chrome-sandbox requires a one-time privileged setup outside the Nix store (either via security.wrappers or sudo)."
    "The x86_64-linux binary is distributed under MPL-2.0; Brave-specific components (Shields, Rewards) carry additional terms."
  ];
}
