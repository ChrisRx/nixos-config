{ pkgs, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # latest Linux kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
