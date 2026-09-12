{ pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
  ];

  core.packages.all.enable = true;
  core.user.extraGroups = [
    "docker"
    "podman"
  ];
  gnome.enable = true;
  networking.hostName = "fw13";
  steam.enable = true;
  nixpkgs.config.allowUnfree = true;

  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend-then-hibernate";
    };
  };
  systemd.sleep.settings = {
    Sleep = {
      HibernateDelaySec = "2h";
      AllowHibernation = "yes";
      AllowSuspendThenHibernate = "yes";
    };
  };

  # Enable cross-compilation builds
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each
      # other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  system.stateVersion = "24.11";
}
