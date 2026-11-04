{ brave-origin }:
{ config, lib, pkgs, ... }: with lib;
let
  cfg         = config.programs.brave-origin;
  desktopFile = "com.brave.Origin.nightly.desktop";
  # XFCE picks its web browser from an exo "helper", not from mimeapps.list.
  xfceHelper  = pkgs.writeTextDir "share/xfce4/helpers/brave-origin.desktop" ''
    [Desktop Entry]
    Version=1.0
    Type=X-XFCE-Helper
    Name=Brave Origin
    Icon=brave-origin
    X-XFCE-Category=WebBrowser
    X-XFCE-Commands=${brave-origin}/bin/brave-origin
    X-XFCE-CommandsWithParameter=${brave-origin}/bin/brave-origin "%s"
  '';
in {
  options.programs.brave-origin = {
    enable = mkEnableOption "Brave Origin (nightly) browser";
    defaultBrowser = mkOption {
      type        = types.bool;
      default     = true;
      description = "Make Brave Origin the system-wide default browser (XDG MIME and XFCE).";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ brave-origin ] ++ optional cfg.defaultBrowser xfceHelper;
    security.wrappers.chrome-sandbox = {
      source = "${brave-origin}/libexec/brave-origin-nightly/chrome-sandbox";
      owner  = "root";
      group  = "root";
      setuid = true;
    };
    xdg.mime.defaultApplications = mkIf cfg.defaultBrowser {
      "text/html"             = desktopFile;
      "application/xhtml+xml" = desktopFile;
      "x-scheme-handler/http"  = desktopFile;
      "x-scheme-handler/https" = desktopFile;
    };
    environment.etc."xdg/xfce4/helpers.rc" = mkIf cfg.defaultBrowser {
      text = "WebBrowser=brave-origin\n";
    };
  };
}
