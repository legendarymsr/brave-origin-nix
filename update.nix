# update.nix — bump brave-origin-nightly to the latest version
#
# Usage (from the repo root):
#   nix run .#update
#
# Queries the GitHub Releases API for the newest release that ships a
# brave-origin-nightly .deb, downloads it, computes the SRI hash, and patches
# pkgs/brave-origin.nix.
#
# Authentication (to avoid the 60 req/h anonymous API rate limit), in order:
#   1. $GITHUB_TOKEN, if set          -> curl with "Authorization: Bearer ..."
#   2. an authenticated `gh` on PATH  -> gh api
#   3. anonymous curl

{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellApplication {
  name = "update-brave-origin";

  runtimeInputs = with pkgs; [ curl python3 gnused gnugrep coreutils jq ];

  text = ''
    NIX_FILE="pkgs/brave-origin.nix"
    REPO="brave/brave-browser"
    API_PATH="repos/$REPO/releases?per_page=50"

    if [ ! -f "$NIX_FILE" ]; then
      echo "error: $NIX_FILE not found; run this from the root of the brave-origin-nix checkout." >&2
      exit 1
    fi

    current=$(grep -m1 'version = ' "$NIX_FILE" | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    echo "Current version: $current"

    errfile=$(mktemp)
    tmp=""
    cleanup() { rm -f "$errfile" ''${tmp:+"$tmp"}; }
    trap cleanup EXIT

    if [ -n "''${GITHUB_TOKEN:-}" ]; then
      mode=token
    elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
      mode=gh
    else
      mode=anonymous
    fi
    echo "Querying GitHub Releases API ($mode)..."

    fetch_releases() {
      case "$mode" in
        token)
          curl -fsSL --max-time 30 \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            "https://api.github.com/$API_PATH" ;;
        gh)
          gh api "$API_PATH" ;;
        *)
          curl -fsSL --max-time 30 \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/$API_PATH" ;;
      esac
    }

    if ! releases=$(fetch_releases 2>"$errfile"); then
      echo "error: could not query the GitHub Releases API for $REPO ($mode):" >&2
      sed 's/^/  /' "$errfile" >&2
      if [ "$mode" = token ]; then
        echo "Check that \$GITHUB_TOKEN is valid (a 401 means it was rejected)." >&2
      else
        echo "This is usually the anonymous API rate limit (60 requests/hour per IP)." >&2
        echo "Set GITHUB_TOKEN=<token> or log in with 'gh auth login', then retry." >&2
      fi
      exit 1
    fi

    # Newest tag that actually has a brave-origin-nightly amd64 .deb asset.
    if ! latest=$(printf '%s' "$releases" | jq -r '
        .[]
        | select(any(.assets[]?; .name | test("^brave-origin-nightly_[0-9.]+_amd64\\.deb$")))
        | .tag_name' 2>"$errfile" \
        | grep -oP '^v?\K[0-9]+\.[0-9]+\.[0-9]+$' | sort -Vr | head -n1); then
      latest=""
    fi

    if [ -z "$latest" ]; then
      echo "error: no release with a brave-origin-nightly_*_amd64.deb asset found in the latest 50 releases of $REPO." >&2
      [ -s "$errfile" ] && sed 's/^/  /' "$errfile" >&2
      exit 1
    fi

    if [ "$latest" = "$current" ]; then
      echo "Already up to date ($current)."
      exit 0
    fi

    url="https://github.com/$REPO/releases/download/v$latest/brave-origin-nightly_''${latest}_amd64.deb"
    echo "New version: $latest"
    echo "Downloading $url to compute hash..."

    tmp=$(mktemp)
    if ! curl -fsSL --max-time 600 -o "$tmp" "$url"; then
      echo "error: failed to download $url" >&2
      exit 1
    fi

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
