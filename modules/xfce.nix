{ config, lib, pkgs, ... }: with lib;

let cfg = config.desktop.xfce; in {

  options.desktop.xfce = {
    enable = mkEnableOption "XFCE desktop environment";

    displayManager = mkOption {
      type    = types.enum [ "lightdm" "gdm" "sddm" ];
      default = "lightdm";
      description = "Display manager to use with XFCE.";
    };

    extraPlugins = mkOption {
      type    = types.listOf types.package;
      default = [];
      example = literalExpression "[ pkgs.xfce4-whiskermenu-plugin ]";
      description = "Additional XFCE panel plugins to install.";
    };
  };

  config = mkIf cfg.enable {

    services.xserver = {
      enable = true;
      desktopManager.xfce.enable = true;
    };

    # Display manager — gdm/sddm live under services.displayManager,
    # lightdm is still under services.xserver.displayManager.
    services.xserver.displayManager.lightdm.enable = cfg.displayManager == "lightdm";
    services.displayManager = {
      gdm.enable     = cfg.displayManager == "gdm";
      sddm.enable    = cfg.displayManager == "sddm";
    };

    # Touchpad support
    services.libinput.enable = true;

    # Common XFCE utilities
    environment.systemPackages = with pkgs; [
      thunar
      thunar-volman
      xfce4-terminal
      xfce4-taskmanager
      xfce4-pulseaudio-plugin
      xfce4-whiskermenu-plugin
      xfce4-notifyd
      xfconf
      gvfs        # trash, network mounts in Thunar
      polkit_gnome
    ] ++ cfg.extraPlugins;

    # Polkit agent so GUI apps can authenticate
    security.polkit.enable = true;
    systemd.user.services.polkit-gnome = {
      description = "Polkit GNOME authentication agent";
      wantedBy    = [ "graphical-session.target" ];
      wants       = [ "graphical-session.target" ];
      after       = [ "graphical-session.target" ];
      serviceConfig.ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    };

    # Thunar volume management
    services.gvfs.enable   = true;
    services.tumbler.enable = true;
  };
}
