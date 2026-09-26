# update.nix — bump brave-origin-nightly to the latest version
#
# Usage:
#   nix run .#update
#
# Queries the GitHub Releases API for the newest brave-origin-nightly .deb,
# downloads it, computes the sha256 hash, and patches pkgs/brave-origin.nix.

{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellApplication {
  name = "update-brave-origin";

  runtimeInputs = with pkgs; [ curl python3 gnused coreutils jq ];

  text = ''
    NIX_FILE="pkgs/brave-origin.nix"

    current=$(grep 'version = ' "$NIX_FILE" | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    echo "Current version: $current"

    # Use the GitHub Releases API to find the latest tag that has a
    # brave-origin-nightly .deb asset — much faster than probing URLs.
    latest=$(curl -fsSL --max-time 15 \
      "https://api.github.com/repos/brave/brave-browser/releases?per_page=50" | \
      jq -r '.[].tag_name' | \
      grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | \
      sort -Vr | \
      while read -r v; do
        code=$(curl -sIo /dev/null -w "%{http_code}" --max-time 5 \
          "https://github.com/brave/brave-browser/releases/download/v$v/brave-origin-nightly_''${v}_amd64.deb")
        if [ "$code" = "302" ]; then
          echo "$v"
          break
        fi
      done)

    if [ -z "$latest" ]; then
      echo "Could not find latest version via GitHub API." >&2
      exit 1
    fi

    if [ "$latest" = "$current" ]; then
      echo "Already up to date ($current)."
      exit 0
    fi

    echo "New version: $latest"
    echo "Downloading to compute hash..."

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT

    curl -fsSL --max-time 300 -o "$tmp" \
      "https://github.com/brave/brave-browser/releases/download/v$latest/brave-origin-nightly_''${latest}_amd64.deb"

    hash=$(sha256sum "$tmp" | awk '{print $1}' | \
      python3 -c "import sys,base64,binascii; print('sha256-' + base64.b64encode(binascii.unhexlify(sys.stdin.read().strip())).decode())")

    echo "Hash: $hash"

    sed -i \
      -e "s|version = \"$current\"|version = \"$latest\"|" \
      -e "s|hash = \"sha256-[^\"]*\"|hash = \"$hash\"|" \
      "$NIX_FILE"

    echo ""
    echo "Updated $NIX_FILE — commit with:"
    echo "  git add $NIX_FILE && git commit -m \"pkgs: bump brave-origin-nightly to $latest\" && git push"
  '';
}
