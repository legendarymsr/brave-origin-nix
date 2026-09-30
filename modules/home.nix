{ brave-origin }:
{ config, lib, ... }: with lib;
let
  cfg = config.programs.brave-origin-nightly;
  desktopFile = "com.brave.Origin.nightly.desktop";
in {
  options.programs.brave-origin-nightly = {
    enable = mkEnableOption "Brave Origin (nightly) browser";

    defaultBrowser = mkOption {
      type    = types.bool;
      default = false;
      description = "Set brave-origin as the default browser for http/https and HTML.";
    };

    extensions = mkOption {
      type    = types.listOf types.str;
      default = [];
      example = [ "cjpalhdlnbpafiamejdnhcphjbkeiagm" ];
      description = ''
        List of Chrome Web Store extension IDs to install via per-profile
        "External Extensions" files (~/.config/BraveSoftware/Brave-Origin-Nightly).
        They are installed on next start; the user can still remove them.
      '';
    };

    commandLineArgs = mkOption {
      type    = types.listOf types.str;
      default = [];
      example = [ "--force-dark-mode" "--disable-smooth-scrolling" ];
      description = "Extra command-line flags passed to brave-origin on startup.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ brave-origin ];

    xdg.mimeApps = mkIf cfg.defaultBrowser {
      enable = true;
      defaultApplications = {
        "text/html"                      = desktopFile;
        "x-scheme-handler/http"          = desktopFile;
        "x-scheme-handler/https"         = desktopFile;
        "x-scheme-handler/ftp"           = desktopFile;
        "application/xhtml+xml"          = desktopFile;
        "application/x-extension-htm"    = desktopFile;
        "application/x-extension-html"   = desktopFile;
        "application/x-extension-xhtml"  = desktopFile;
        "application/x-extension-xht"    = desktopFile;
      };
    };

    # Chromium never reads managed policies from $HOME; use per-profile
    # "External Extensions" files instead (installed, but user-removable).
    home.file = listToAttrs (map (id: {
      name  = ".config/BraveSoftware/Brave-Origin-Nightly/External Extensions/${id}.json";
      value.text = builtins.toJSON {
        external_update_url = "https://clients2.google.com/service/update2/crx";
      };
    }) cfg.extensions);

    xdg.desktopEntries = mkIf (cfg.commandLineArgs != []) {
      "com.brave.Origin.nightly" = {
        name       = "Brave Origin";
        exec       = "brave-origin ${lib.escapeShellArgs cfg.commandLineArgs} %U";
        icon       = "brave-origin";
        comment    = "Brave browser — Origin (nightly) channel";
        categories = [ "Network" "WebBrowser" ];
        mimeType   = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
      };
    };
  };
}
