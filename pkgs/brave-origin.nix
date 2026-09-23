{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, wrapGAppsHook3,
  alsa-lib, at-spi2-atk, cairo, cups, dbus, expat, fontconfig, gdk-pixbuf,
  glib, gtk3, libX11, libXScrnSaver, libxcb, libXcomposite, libXcursor,
  libXdamage, libXext, libXfixes, libXi, libXrandr, libXrender, libXtst,
  libdrm, libgbm, libuuid, libxshmfence, libXinerama, mesa, nspr, nss,
  pango, systemd, xdg-utils }:

stdenv.mkDerivation rec {
  pname   = "brave-origin";
  version = "1.97.24";

  src = fetchurl {
    url  = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-origin-nightly_${version}_amd64.deb";
    hash = "sha256-A7hpK3dD5b22V/3gl67lp0snUkL7w10BV+WXCUH11+4=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];

  buildInputs = [
    alsa-lib at-spi2-atk cairo cups dbus expat fontconfig gdk-pixbuf glib gtk3
    libX11 libXScrnSaver libxcb libXcomposite libXcursor libXdamage libXext
    libXfixes libXi libXrandr libXrender libXtst libdrm libgbm libuuid
    libxshmfence libXinerama mesa nspr nss pango systemd
  ];

  autoPatchelfIgnoreMissingDeps = true;

  unpackPhase = "dpkg-deb --fsys-tarfile $src | tar x --no-same-permissions";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec $out/share/applications $out/share/icons
    cp -r opt/brave.com/brave-origin-nightly $out/libexec/
    chmod +x $out/libexec/brave-origin-nightly/brave-origin-nightly
    cp -r usr/share/applications/. $out/share/applications/ 2>/dev/null || true
    cp -r usr/share/icons/.        $out/share/icons/        2>/dev/null || true

    shopt -s nullglob
    desktopFiles=($out/share/applications/*.desktop)
    for f in "''${desktopFiles[@]}"; do
      substituteInPlace "$f" \
        --replace-quiet "/usr/bin/brave-origin-nightly" "$out/bin/brave-origin" \
        --replace-quiet "brave-origin-nightly" "brave-origin" || true
    done
    if [ "''${#desktopFiles[@]}" -eq 1 ]; then
      mv "''${desktopFiles[0]}" "$out/share/applications/brave-origin.desktop"
    fi

    makeWrapper $out/libexec/brave-origin-nightly/brave-origin-nightly $out/bin/brave-origin \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --suffix PATH          : "${xdg-utils}/bin" \
      --run ${lib.escapeShellArg ''
        if [ ! -x /run/wrappers/bin/chrome-sandbox ]; then
          sudo -n install -D -m 4755 -o root -g root \
            "${placeholder "out"}/libexec/brave-origin-nightly/chrome-sandbox" \
            /run/wrappers/bin/chrome-sandbox 2>/dev/null || true
        fi
        if [ -x /run/wrappers/bin/chrome-sandbox ]; then
          export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chrome-sandbox
          SANDBOX_FLAG=""
        else
          SANDBOX_FLAG="--no-sandbox"
        fi
      ''} \
      --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations \$SANDBOX_FLAG"
    runHook postInstall
  '';

  meta = with lib; {
    description      = "Brave Origin — nightly channel";
    homepage         = "https://brave.com/origin/";
    license          = licenses.mpl20;
    platforms        = [ "x86_64-linux" ];
    mainProgram      = "brave-origin";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
