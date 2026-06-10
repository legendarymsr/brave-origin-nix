# brave-origin-nix

Brave Origin (nightly) browser packaged as a Nix flake.

## Run without installing
```
sudo nix run github:legendarymsr/brave-origin-nix --no-write-lock-file --refresh
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
`security.wrappers.chrome-sandbox`, so the browser runs fully sandboxed when
installed through `nixosModules.brave-origin`.

If run standalone via `nix run github:legendarymsr/brave-origin-nix` (without
the NixOS module), the wrapper at `/run/wrappers/bin/chrome-sandbox` won't
exist, and the browser falls back to `--no-sandbox`.
