# brave-origin-nix

Brave Origin (nightly) browser packaged as a Nix flake.

## Run without installing
```
nix run github:legendarymsr/brave-origin-nix --no-write-lock-file --refresh
```

## home-manager
In your flake inputs:
```nix
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
```

In your home-manager configuration:
```nix
imports = [ inputs.brave-origin.homeManagerModules.brave-origin ];
programs.brave-origin = {
  enable = true;
  defaultBrowser = true; # optional, sets brave-origin as the default browser
};
```

## NixOS
```nix
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
imports = [ inputs.brave-origin.nixosModules.brave-origin ];
programs.brave-origin.enable = true;
```

## Sandboxing

The Chromium sandbox needs `chrome-sandbox` to run as setuid root, which the
Nix store does not allow. The NixOS module sets this up automatically via
`security.wrappers.chrome-sandbox`.

When run standalone via `nix run`, brave-origin will try to set up
`/run/wrappers/bin/chrome-sandbox` itself using `sudo -n` (non-interactive,
only works if you have cached sudo credentials). If that's not available, it
falls back to `--no-sandbox`.

To set it up manually once (recommended for standalone use):
```
sudo install -D -m 4755 -o root -g root \
  "$(nix build github:legendarymsr/brave-origin-nix --no-link --print-out-paths)/libexec/brave-nightly/chrome-sandbox" \
  /run/wrappers/bin/chrome-sandbox
```
After that, every `nix run` will use the proper sandbox automatically.
