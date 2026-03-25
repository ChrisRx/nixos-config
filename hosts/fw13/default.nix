{ ... }: {
  imports = [ ./hardware-configuration.nix ../../modules/nixos/core ];

  core.packages.all.enable = true;
  core.user.extraGroups = [ "docker" ];
  gnome.enable = true;
  networking.hostName = "fw13";
  steam.enable = true;

  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.logind.settings = {
    Login = { HandleLidSwitch = "suspend-then-hibernate"; };
  };
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=7200
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
  '';

  # Enable cross-compilation builds
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  system.stateVersion = "24.11";
}
