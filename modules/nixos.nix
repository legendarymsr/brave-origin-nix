{ config, lib, brave-origin, ... }: with lib; {
  options.programs.brave-origin.enable = mkEnableOption "Brave Origin (nightly) browser";
  config = mkIf config.programs.brave-origin.enable {
    environment.systemPackages = [ brave-origin ];
    security.wrappers.chrome-sandbox = {
      source = "${brave-origin}/libexec/brave-nightly/chrome-sandbox";
      owner  = "root";
      group  = "root";
      setuid = true;
    };
  };
}
