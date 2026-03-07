{ username, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    ../../modules/nixos/gnome
    ../../modules/nixos/steam
    <nixos-hardware/framework/13-inch/amd-ai-300-series>
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  hardware.bluetooth.enable = true;

  home-manager.users.${username}.packages.extra.enable = true;
  home-manager.users.${username}.packages.experimental.enable = true;
  home-manager.users.${username}.packages.fonts.enable = true;

  networking.hostName = "fw13";

  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  # XXX:
  services.xserver.enable = true;

  services.logind = { lidSwitch = "suspend-then-hibernate"; };
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=7200
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
  '';

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-25.05";

  users.users.${username}.extraGroups = [ "docker" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
