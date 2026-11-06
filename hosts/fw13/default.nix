{ lib, pkgs, ... }: {
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
    plugins = {
      gloview.enable = true;
      kineticScroll.enable = false;
      hyprWorld.enable = true;
    };
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

  # 7.3.0 oopses in mt7925e_mac_reset() when the wifi firmware times out while
  # devices thaw after the hibernate snapshot, so the image is never written
  # and the machine sits dark until forced off. Introduced by c4edf9e3e0e5
  # ("wifi: mt76: mt7925: replace shared rx irq masks with per-chip
  # definitions"), fixed upstream by c182bfe944eb ("wifi: mt76: mt7925: fix
  # reset panic caused by the WM2 rx irq mask"). Drop this pin once a 7.3.x
  # release carries the fix.
  core.kernel.version = "7.2";

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
  # The containers module only writes the v1 format, so registries.conf is
  # replaced outright and virtualisation.containers.registries no longer
  # applies.
  environment.etc."containers/registries.conf".source = lib.mkForce (
    (pkgs.formats.toml { }).generate "registries.conf" {
      unqualified-search-registries = [
        "docker.io"
        "quay.io"
      ];
      registry = [
        # Needed for k3d image registry pushes
        {
          location = "127.0.0.1:5005";
          insecure = true;
        }
      ];
    }
  );

  # Rootless kind under podman. The kubelet in the node container needs the
  # cpuset controller, which systemd's stock user@.service leaves out of its
  # Delegate=pids memory cpu.
  systemd.services."user@".serviceConfig.Delegate = "yes";
  # A rootless container cannot load kernel modules, so the ones kube-proxy's
  # iptables rules need have to be loaded on the host up front.
  boot.kernelModules = [
    "ip6_tables"
    "ip6table_nat"
    "ip_tables"
    "iptable_nat"
  ];
  # Without this kind finds dockerCompat's `docker` shim and drives podman
  # through the docker provider.
  environment.sessionVariables.KIND_EXPERIMENTAL_PROVIDER = "podman";

  system.stateVersion = "24.11";
}
