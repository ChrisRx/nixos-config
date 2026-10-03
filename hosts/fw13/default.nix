{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
  ];

  core.packages.all.enable = true;
  core.user.extraGroups = [
    "docker"
    "podman"
  ];
  desktop.gnome.enable = true;
  desktop.hyprland = {
    enable = true;
    mutableConfig = true;
  };
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
      HibernateOnACPower = "no";
    };
  };

  # Hibernate writes the whole image to one swap area, and the 8.8G partition
  # in ./hardware-configuration.nix is too small for it. The kernel snapshots
  # ~24G (image_size defaults to 2/5 of the 62G of RAM) and leans on lzo to fit
  # that into swap, so hibernate only worked when the pages happened to
  # compress well enough. On 2026-10-01 it managed 1.9:1, failed at 70% with
  # ENOSPC, fell back to plain suspend, and the battery drained overnight.
  #
  # At 64G the file is larger than RAM, so the image fits at any compression
  # ratio. The partition stays on as ordinary swap; this is the resume target.
  # Hibernating to a file needs both the device holding it and the offset of
  # its first extent, which `filefrag -v /swapfile` reports.
  # The priority also decides which area systemd hibernates into. Left at the
  # default both areas sit at -1 and the partition is the one listed first in
  # /proc/swaps, so the choice rests on a tie-break systemd does not document.
  # An explicit priority settles it on the only area big enough.
  swapDevices = [
    {
      device = "/swapfile";
      size = 65536; # MiB
      priority = 100;
    }
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/ae781775-f624-4458-9ec1-1faf18e110d2";
  # Block holding the swap header, from the first extent of `filefrag -v`. Only
  # the header is located this way; the image pages chain by absolute block, so
  # it does not matter that the file is fragmented. Recreating /swapfile moves
  # the header and invalidates this number.
  boot.kernelParams = [ "resume_offset=354342912" ];

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
