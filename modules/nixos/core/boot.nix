{ pkgs, lib, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # latest Linux kernel, as a default so a host can pin its own without needing
  # lib.mkForce (see hosts/fw13 for a host frozen to an EOL kernel).
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
}
