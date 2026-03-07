{ pkgs, ... }: {
  services.system76-scheduler.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # environment.etc."libinput-gestures.conf" = {
  #   text = ''
  #     # Show workspaces overview - 3 fingers
  #     gesture swipe up    3 cosmic-workspaces
  #     gesture swipe down  3 cosmic-workspaces
  #   '';
  #   mode = "444";
  # };
  #
  # services.libinput.enable = true;
  #
  # environment.systemPackages = with pkgs; [
  #   libinput
  #   libinput-gestures
  #   wmctrl
  #   ydotool
  #   xdotool
  # ];
}
