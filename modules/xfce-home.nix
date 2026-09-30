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
      };

      # Keybindings. Launcher commands and xfwm4 window actions both live in
      # the xfce4-keyboard-shortcuts channel, using GTK accelerator syntax.
      #
      # We deliberately do NOT set commands/custom/override or
      # xfwm4/custom/override: on first login XFCE clones its stock defaults
      # into custom/ when override is unset, so Alt+Tab etc. keep working and
      # these entries are layered on top. (On a brand-new profile the clone
      # wipes custom/ once, so the bindings below apply from the next
      # home-manager activation after the first XFCE login.)
      xfce4-keyboard-shortcuts = {
        "commands/custom/<Super>b"          = "brave-origin";
        "commands/custom/<Super>e"          = "thunar";
        "commands/custom/<Super>t"          = "xfce4-terminal";
        "commands/custom/<Super>Escape"     = "xflock4";
        "commands/custom/<Super>d"          = "xfdesktop --menu";
        "commands/custom/Print"             = "xfce4-screenshooter";
        # Stock defaults that clash with the bindings here (null = remove).
        "commands/custom/<Super>l"          = null;  # xflock4 -> tile_right_key
        "xfwm4/custom/<Super>d"             = null;  # show_desktop_key -> desktop menu

        "xfwm4/custom/<Alt>F4"              = "close_window_key";
        "xfwm4/custom/<Super>h"             = "tile_left_key";
        "xfwm4/custom/<Super>l"             = "tile_right_key";
        "xfwm4/custom/<Super>k"             = "maximize_window_key";
        "xfwm4/custom/<Super>j"             = "hide_window_key";
        "xfwm4/custom/<Super>Tab"           = "cycle_windows_key";
        "xfwm4/custom/<Super><Shift>h"      = "move_window_prev_workspace_key";
        "xfwm4/custom/<Super><Shift>l"      = "move_window_next_workspace_key";
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

  };
}
