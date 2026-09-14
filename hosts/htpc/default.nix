{
  username,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/nixos/core
    ./../../modules/nixos/gnome
    ./../../modules/nixos/nvidia
    ./../../modules/nixos/steam
  ];

  core.kernel.version = "7.1.13";

  core.packages = {
    development.enable = true;
    extra.enable = true;
    utils.enable = true;
  };
  gnome.enable = true;
  networking.hostName = "htpc";

  nvidia.enable = true;
  nvidia.powerLimit = 300;
  nvidia.usePatchedPackage = false;
  hardware.nvidia.nvidiaPersistenced = true;

  steam.enable = true;

  home-manager.users.${username}.home.packages = with pkgs; [
    pcsx2
    azahar
  ];

  systemd = {
    targets.sleep.enable = false;
    targets.suspend.enable = false;
    targets.hibernate.enable = false;
    targets.hybrid-sleep.enable = false;
  };
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
    };
  };

  fileSystems = builtins.listToAttrs (
    map
      (
        share:
        lib.nameValuePair "/mnt/${share}" {
          device = "//storage.oldtech.internal/${share}";
          fsType = "cifs";
          options = [
            (lib.strings.join "," [
              "x-systemd.automount"
              "noauto"
              "x-systemd.idle-timeout=60"
              "x-systemd.device-timeout=5s"
              "x-systemd.mount-timeout=5s"
              "credentials=/etc/nixos/smb-secrets"
              "uid=${username}"
              "gid=users"
            ])
          ];
        }
      )
      [
        "media"
        "public"
      ]
  );

  # TODO: disable again when debug finished
  services.openssh.enable = false;

  system.stateVersion = "25.11";
}
