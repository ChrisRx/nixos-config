{ inputs, username, lib, ... }: {
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
  nvidia.usePatchedPackage = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.logind.settings = { Login = { HandleLidSwitch = "ignore"; }; };

  home-manager.users.${username}.packages.experimental.enable = true;
  users.users.${username}.extraGroups = [ "docker" ];

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

  # TODO: disable again when debug finished
  services.openssh.enable = true;

  system.stateVersion = "25.11";
}
