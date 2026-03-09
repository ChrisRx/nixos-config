{ username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    ../../modules/nixos/gnome
    ../../modules/nixos/steam
  ];

  core.user.extraGroups = [ "docker" ];

  networking.hostName = "fw13";
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

  home-manager.users.${username}.packages = {
    extra.enable = true;
    experimental.enable = true;
    fonts.enable = true;
  };

  # Enable cross-compilation builds
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  system.stateVersion = "24.11";
}
