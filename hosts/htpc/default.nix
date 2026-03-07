{ inputs, pkgs, username, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./../../modules/nixos/core
    ./../../modules/nixos/gnome
    ./../../modules/nixos/nvidia
    ./../../modules/nixos/steam
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "htpc";

  nvidia.enable = true;
  nvidia.powerLimit = 250;

  services.fwupd.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.logind.lidSwitch = "ignore";

  home-manager.users.${username}.packages.experimental.enable = true;

  fileSystems."/mnt/media" =
    lib.mkIf (builtins.pathExists /etc/nixos/smb-secrets) {
      device = "//storage.oldtech.internal/media";
      fsType = "cifs";
      options = let
        # this line prevents hanging on network split
        automount_opts =
          "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

      in [
        "${automount_opts},credentials=/etc/nixos/smb-secrets,uid=1000,gid=100"
      ];
    };

  users.users.${username}.extraGroups = [ "docker" ];

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-25.11";

  # TODO: disable again when debug finished
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
