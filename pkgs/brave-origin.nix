{ lib, stdenv, fetchurl, dpkg, autoPatchelfHook, makeWrapper, wrapGAppsHook3,
  alsa-lib, at-spi2-atk, cairo, cups, dbus, expat, fontconfig, gdk-pixbuf,
  glib, gtk3, libX11, libXScrnSaver, libXcb, libXcomposite, libXcursor,
  libXdamage, libXext, libXfixes, libXi, libXrandr, libXrender, libXtst,
  libdrm, libgbm, libuuid, mesa, nspr, nss, pango, systemd, xdg-utils, xorg }:

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
    libX11 libXScrnSaver libXcb libXcomposite libXcursor libXdamage libXext
    libXfixes libXi libXrandr libXrender libXtst libdrm libgbm libuuid mesa
    nspr nss pango systemd xorg.libxshmfence xorg.libXinerama
  ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/applications $out/share/icons
    cp -r opt/brave.com/brave-browser-nightly $out/libexec
    cp -r usr/share/applications/. $out/share/applications/ 2>/dev/null || true
    cp -r usr/share/icons/.        $out/share/icons/        2>/dev/null || true
    substituteInPlace $out/share/applications/brave-browser-nightly.desktop \
      --replace-quiet "/usr/bin/brave-browser-nightly" "$out/bin/brave-origin" \
      --replace-quiet "brave-browser-nightly" "brave-origin"
    makeWrapper $out/libexec/brave-browser-nightly $out/bin/brave-origin \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --suffix PATH          : "${xdg-utils}/bin" \
      --add-flags "--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations"
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
