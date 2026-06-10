{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, wrapGAppsHook3,
  alsa-lib, at-spi2-atk, cairo, cups, dbus, expat, fontconfig, gdk-pixbuf,
  glib, gtk3, libX11, libXScrnSaver, libxcb, libXcomposite, libXcursor,
  libXdamage, libXext, libXfixes, libXi, libXrandr, libXrender, libXtst,
  libdrm, libgbm, libuuid, libxshmfence, libXinerama, mesa, nspr, nss,
  pango, systemd, xdg-utils, xorg }:

stdenv.mkDerivation rec {
  pname   = "brave-origin";
  version = "1.93.47";

  src = fetchurl {
    url  = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser-nightly_${version}_amd64.deb";
    hash = "sha256-oPQsPwc/lc6Cy1ggo2hOlf7VEccBemZl/UiXSq7LahY=";
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
    cp -r opt/brave.com/brave-nightly $out/libexec/
    chmod +x $out/libexec/brave-nightly/brave-browser-nightly
    cp -r usr/share/applications/. $out/share/applications/ 2>/dev/null || true
    cp -r usr/share/icons/.        $out/share/icons/        2>/dev/null || true
    for f in $out/share/applications/*.desktop; do
      substituteInPlace $f \
        --replace-quiet "/usr/bin/brave-browser-nightly" "$out/bin/brave-origin" \
        --replace-quiet "brave-browser-nightly" "brave-origin" || true
      mv "$f" "$out/share/applications/brave-origin.desktop"
    done
    makeWrapper $out/libexec/brave-nightly/brave-browser-nightly $out/bin/brave-origin \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --suffix PATH          : "${xdg-utils}/bin" \
      --run 'if [ -x /run/wrappers/bin/chrome-sandbox ]; then export CHROME_DEVEL_SANDBOX=/run/wrappers/bin/chrome-sandbox; SANDBOX_FLAG=""; else SANDBOX_FLAG="--no-sandbox"; fi' \
      --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations \$SANDBOX_FLAG"
    runHook postInstall
  '';

  meta = with lib; {
    description      = "Brave browser — Origin (nightly) channel";
    homepage         = "https://brave.com";
    license          = licenses.mpl20;
    platforms        = [ "x86_64-linux" ];
    mainProgram      = "brave-origin";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
