{ config, lib, pkgs, brave-origin, ... }: with lib;
let cfg = config.programs.brave-origin; in {
  options.programs.brave-origin = {
    enable        = mkEnableOption "Brave Origin (nightly) browser";
    defaultBrowser = mkOption { type = types.bool; default = false;
      description = "Set brave-origin as the default browser."; };
  };
  config = mkIf cfg.enable {
    home.packages = [ brave-origin ];
    xdg.mimeApps = mkIf cfg.defaultBrowser {
      enable = true;
      defaultApplications = {
        "text/html"               = "brave-browser-nightly.desktop";
        "x-scheme-handler/http"  = "brave-browser-nightly.desktop";
        "x-scheme-handler/https" = "brave-browser-nightly.desktop";
      };
    };
  };
}
