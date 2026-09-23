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

  # Optional: set brave-origin as the default browser
  defaultBrowser = true;

  # Optional: force-install Chrome Web Store extensions by ID
  extensions = [
    "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
  ];

  # Optional: extra command-line flags
  commandLineArgs = [
    "--force-dark-mode"
  ];
};
```

### home-manager options

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Install brave-origin |
| `defaultBrowser` | bool | `false` | Set as default browser for http/https/HTML |
| `extensions` | list of strings | `[]` | Chrome Web Store extension IDs to force-install |
| `commandLineArgs` | list of strings | `[]` | Extra flags passed to the browser on startup |

## NixOS

In your flake inputs:
```nix
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
```

In your NixOS configuration:
```nix
imports = [ inputs.brave-origin.nixosModules.brave-origin ];
programs.brave-origin.enable = true;
```

The NixOS module also sets up the `chrome-sandbox` setuid wrapper automatically
via `security.wrappers`, so the browser runs with a proper sandbox.

## XFCE

The point of this flake is Brave Origin. XFCE is here purely so you don't have
to mess with multiple flakes — if you're setting up a fresh NixOS machine, you
can get a working desktop and browser from a single input without thinking about
it. Stock XFCE, nothing fancy, stays out of the way.

If you already have a desktop, just ignore this and use the `brave-origin`
modules above.

Keybindings included out of the box:

| Shortcut | Action |
|---|---|
| `Super + B` | Launch Brave Origin |
| `Super + T` | Terminal |
| `Super + E` | File manager (Thunar) |
| `Super + L` | Lock screen |
| `Super + H/L` | Tile window left/right |
| `Super + K` | Maximise |
| `Super + J` | Minimise |
| `Super + Tab` | Cycle windows |
| `Super + Shift + H/L` | Move window to prev/next workspace |
| `Print` | Screenshot |

**One flake, one `nixos-rebuild switch`:**

```nix
{
  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    brave-origin.url = "github:legendarymsr/brave-origin-nix";
  };

  outputs = { nixpkgs, home-manager, brave-origin, ... }: {
    nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        brave-origin.nixosModules.brave-origin
        brave-origin.nixosModules.xfce
        home-manager.nixosModules.home-manager
        {
          programs.brave-origin.enable = true;
          desktop.xfce.enable          = true;

          home-manager.users.youruser = {
            imports = [
              brave-origin.homeManagerModules.brave-origin
              brave-origin.homeManagerModules.xfce
            ];
            programs.brave-origin.enable        = true;
            programs.brave-origin.defaultBrowser = true;
            desktop.xfce.enable                 = true;
            home.stateVersion                   = "24.11";
          };
        }
      ];
    };
  };
}
```

## Sandboxing

The Chromium sandbox requires `chrome-sandbox` to be setuid root, which the
Nix store cannot provide. The NixOS module handles this automatically via
`security.wrappers.chrome-sandbox`.

When run standalone via `nix run`, brave-origin will try to set up
`/run/wrappers/bin/chrome-sandbox` itself using `sudo -n` (non-interactive;
only works if you have cached sudo credentials). If that fails, it falls back
to `--no-sandbox`.

To set it up manually once (recommended for standalone use):
```
sudo install -D -m 4755 -o root -g root \
  "$(nix build github:legendarymsr/brave-origin-nix --no-link --print-out-paths)/libexec/brave-origin-nightly/chrome-sandbox" \
  /run/wrappers/bin/chrome-sandbox
```
After that, every `nix run` invocation will use the proper sandbox automatically.
