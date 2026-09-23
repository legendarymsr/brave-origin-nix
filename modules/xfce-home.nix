{ config, lib, pkgs, ... }: with lib;

let cfg = config.desktop.xfce; in {

  options.desktop.xfce = {
    enable = mkEnableOption "XFCE home-manager integration";

    theme = mkOption {
      type    = types.str;
      default = "Adwaita-dark";
      description = "GTK/XFCE window manager theme name.";
    };

    iconTheme = mkOption {
      type    = types.str;
      default = "hicolor";
      description = "Icon theme name.";
    };

    terminalFont = mkOption {
      type    = types.str;
      default = "Monospace 11";
      description = "Font for xfce4-terminal (Pango font string).";
    };
  };

  config = mkIf cfg.enable {

    # GTK theming
    gtk = {
      enable = true;
      theme.name      = cfg.theme;
      iconTheme.name  = cfg.iconTheme;
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    # XFCE settings via xfconf
    xfconf.settings = {

      xfwm4 = {
        "general/theme"           = cfg.theme;
        "general/title_font"      = "Sans Bold 9";
        "general/button_layout"   = "O|HMC";
        "general/use_compositing" = true;
        "general/frame_opacity"   = 100;

        # Keybindings
        "shortcuts/custom/Super+b"          = "brave-origin";
        "shortcuts/custom/Super+e"          = "thunar";
        "shortcuts/custom/Super+t"          = "xfce4-terminal";
        "shortcuts/custom/Super+l"          = "xflock4";
        "shortcuts/custom/Super+d"          = "xfdesktop --menu";
        "shortcuts/custom/Print"            = "xfce4-screenshooter";
        "shortcuts/custom/Alt+F4"           = "close_window_key";
        "shortcuts/custom/Super+Left"       = "tile_left_key";
        "shortcuts/custom/Super+Right"      = "tile_right_key";
        "shortcuts/custom/Super+Up"         = "maximize_window_key";
        "shortcuts/custom/Super+Down"       = "hide_window_key";
        "shortcuts/custom/Super+Tab"        = "cycle_windows_key";
        "shortcuts/custom/Super+shift+Left"  = "move_window_prev_workspace_key";
        "shortcuts/custom/Super+shift+Right" = "move_window_next_workspace_key";
      };

      xsettings = {
        "Net/ThemeName"         = cfg.theme;
        "Net/IconThemeName"     = cfg.iconTheme;
        "Gtk/FontName"          = "Sans 10";
        "Gtk/MonospaceFontName" = cfg.terminalFont;
      };

      xfce4-terminal = {
        "font-name"                     = cfg.terminalFont;
        "misc-show-unsafe-paste-dialog" = false;
        "misc-copy-on-select"           = true;
        "scrolling-unlimited"           = true;
      };

      xfce4-panel = {
        "panels"                       = [ 1 ];
        "panels/panel-1/position"      = "p=6;x=0;y=0";
        "panels/panel-1/size"          = 28;
        "panels/panel-1/length"        = 100;
        "panels/panel-1/length-adjust" = true;
      };

      thunar = {
        "last-show-hidden"    = false;
        "misc-single-click"   = false;
        "misc-thumbnail-mode" = "THUNAR_THUMBNAIL_MODE_ALWAYS";
      };
    };

    # Brave Origin as default browser in XFCE
    xdg.mimeApps.defaultApplications = {
      "text/html"              = "brave-origin.desktop";
      "x-scheme-handler/http"  = "brave-origin.desktop";
      "x-scheme-handler/https" = "brave-origin.desktop";
    };
  };
}
