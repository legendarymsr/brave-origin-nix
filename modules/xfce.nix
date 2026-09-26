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
      example = literalExpression "[ pkgs.xfce.xfce4-whiskermenu-plugin ]";
      description = "Additional XFCE panel plugins to install.";
    };
  };

  config = mkIf cfg.enable {

    services.xserver = {
      enable = true;
      desktopManager.xfce.enable = true;
    };

    # Display manager — config lives under services.displayManager on nixos-unstable
    services.displayManager = {
      lightdm.enable = cfg.displayManager == "lightdm";
      gdm.enable     = cfg.displayManager == "gdm";
      sddm.enable    = cfg.displayManager == "sddm";
    };

    # Touchpad support
    services.libinput.enable = true;

    # Common XFCE utilities
    environment.systemPackages = with pkgs; [
      xfce.thunar
      xfce.thunar-volman
      xfce.xfce4-terminal
      xfce.xfce4-taskmanager
      xfce.xfce4-pulseaudio-plugin
      xfce.xfce4-whiskermenu-plugin
      xfce.xfce4-notifyd
      xfce.xfconf
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
