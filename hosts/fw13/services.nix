{ config, pkgs, ... }:
{
  services = {
    fwupd.enable = true;
    fprintd.enable = true;
    hardware.bolt.enable = true;

    xserver = {
      enable = true;

      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
        options = "caps:ctrl_modifier";
      };
    };

    # who be printing?
    printing.enable = false;
  };

  services.logind = {
    lidSwitch = "suspend-then-hibernate";
  };
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=7200
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
  '';
}
