# brave-origin-nix

Brave Origin (nightly) browser packaged as a Nix flake.

> The README is also available as a `.nix` file because everything is a `.nix` file.

---

## Updating

Bump to the latest nightly version:

```bash
nix run .#update
```

Finds the latest release, downloads it, recomputes the hash, and patches `pkgs/brave-origin.nix`. Then commit and push.

---

## Run without installing

```bash
nix run github:legendarymsr/brave-origin-nix --no-write-lock-file --refresh
```

---

## home-manager

In your flake inputs:

```nix
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";
```

In your home-manager configuration:

```nix
imports = [ inputs.brave-origin.homeManagerModules.brave-origin ];

programs.brave-origin = {
  enable          = true;
  defaultBrowser  = true;                              # optional
  extensions      = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ]; # optional — CWS ID
  commandLineArgs = [ "--force-dark-mode" ];           # optional
};
```

### Options

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Install brave-origin |
| `defaultBrowser` | bool | `false` | Set as default browser for http/https/HTML |
| `extensions` | list of strings | `[]` | Chrome Web Store extension IDs to force-install |
| `commandLineArgs` | list of strings | `[]` | Extra flags passed to the browser on startup |

---

## NixOS

```nix
inputs.brave-origin.url = "github:legendarymsr/brave-origin-nix";

imports = [ inputs.brave-origin.nixosModules.brave-origin ];
programs.brave-origin.enable = true;
```

The NixOS module sets up the `chrome-sandbox` setuid wrapper automatically via `security.wrappers`.

---

## XFCE

The point of this flake is Brave Origin. XFCE is here purely so you don't have to mess with multiple flakes. Stock XFCE, stays out of the way. If you already have a desktop just ignore this.

### Keybindings

| Shortcut | Action |
|---|---|
| `Super + B` | Launch Brave Origin |
| `Super + T` | Terminal |
| `Super + E` | File manager (Thunar) |
| `Super + Shift + L` | Lock screen |
| `Super + H/L` | Tile window left/right |
| `Super + K` | Maximise |
| `Super + J` | Minimise |
| `Super + Tab` | Cycle windows |
| `Super + Shift + H/L` | Move to prev/next workspace |
| `Print` | Screenshot |

### One flake, one `nixos-rebuild switch`

Browser + desktop + editor, nothing else needed:

```nix
{
  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    brave-origin.url = "github:legendarymsr/brave-origin-nix";
    # nixvim is re-exported by brave-origin — no extra input needed
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
              brave-origin.homeManagerModules.nixvim
            ];
            programs.brave-origin.enable        = true;
            programs.brave-origin.defaultBrowser = true;
            desktop.xfce.enable                 = true;
            programs.nixvim-simple.enable       = true;
            home.stateVersion                   = "24.11";
          };
        }
      ];
    };
  };
}
```

---

## Sandboxing

The NixOS module handles `chrome-sandbox` automatically via `security.wrappers`.

For standalone `nix run`, brave-origin tries `sudo -n` first and falls back to `--no-sandbox`.

Manual one-time setup:

```bash
sudo install -D -m 4755 -o root -g root \
  "$(nix build github:legendarymsr/brave-origin-nix --no-link --print-out-paths)/libexec/brave-origin-nightly/chrome-sandbox" \
  /run/wrappers/bin/chrome-sandbox
```

---

## Text editor

Minimal nixvim — no extra flake input needed, re-exported by this flake:

```nix
imports = [ inputs.brave-origin.homeManagerModules.nixvim ];
programs.nixvim-simple.enable = true;
```

**Features:** relative numbers · nixd (Nix LSP) · nvim-cmp · treesitter · telescope · catppuccin mocha · lualine

| Keybind | Action |
|---|---|
| `Space + FF` | Find files |
| `Space + FG` | Live grep |
| `Space + FB` | Buffers |
| `Space + E` | File explorer |
| `Ctrl + H/J/K/L` | Navigate splits |
| `Tab / Shift+Tab` | Cycle completions |
| `Enter` | Confirm completion |
