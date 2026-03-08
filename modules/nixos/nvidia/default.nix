{ config, lib, pkgs, ... }:

let cfg = config.nvidia;
in {
  options.nvidia = {
    enable = lib.mkEnableOption "Enable nvidia gpu";

    usePatchedPackage =
      lib.mkEnableOption "Use NVidia package with 6.19 kernel patch";

    powerLimit = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "Limit gpu power usage (watts)";
    };
  };
  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      nvidiaSettings = true;
      modesetting.enable = true;
      powerManagement.enable = true;

    };

    # Apply CachyOS kernel 6.19 patch to NVIDIA latest driver (optional)
    hardware.nvidia.package = lib.mkIf cfg.usePatchedPackage (let
      base = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "590.48.01";
        sha256_64bit = "sha256-ueL4BpN4FDHMh/TNKRCeEz3Oy1ClDWto1LO/LWlr1ok=";
        openSha256 = "sha256-hECHfguzwduEfPo5pCDjWE/MjtRDhINVr4b1awFdP44=";
        settingsSha256 = "sha256-4SfCWp3swUp+x+4cuIZ7SA5H7/NoizqgPJ6S9fm90fA=";
        persistencedSha256 = "";
      };
      cachyos-nvidia-patch = pkgs.fetchpatch {
        url =
          "https://raw.githubusercontent.com/CachyOS/CachyOS-PKGBUILDS/master/nvidia/nvidia-utils/kernel-6.19.patch";
        sha256 = "sha256-YuJjSUXE6jYSuZySYGnWSNG5sfVei7vvxDcHx3K+IN4=";
      };

      # Patch the appropriate driver based on config.hardware.nvidia.open
      driverAttr = if config.hardware.nvidia.open then "open" else "bin";
    in base // {
      ${driverAttr} = base.${driverAttr}.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [ cachyos-nvidia-patch ];
      });
    });

    systemd.services.nvidia-power-limit = lib.mkIf (cfg.powerLimit != 0) {
      description = "Set the power limit for NVIDIA gpu";
      serviceConfig = {
        Type = "oneshot";
        ExecStart =
          "${pkgs.bash}/bin/bash -c '/run/current-system/sw/bin/nvidia-smi -pm 1 && /run/current-system/sw/bin/nvidia-smi -pl 250'";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
