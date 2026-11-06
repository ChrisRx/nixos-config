{ pkgs, lib, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # latest Linux kernel, as a default so a host can pin its own without needing
  # lib.mkForce (see hosts/fw13 for a host frozen to an EOL kernel).
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # keep oops/panic dumps out of NVRAM. each dump writes several efivars that
  # systemd-pstore deletes, but the firmware only reclaims the space later, so
  # repeated crashes fill the variable store.
  boot.kernelParams = [ "efi_pstore.pstore_disable=1" ];

  # warn on the desktop when the EFI variable store is close to full.
  systemd.user.services.efivars-usage = {
    description = "Warn when efivars usage is high";
    path = [ pkgs.coreutils pkgs.libnotify ];
    serviceConfig.Type = "oneshot";
    script = ''
      used=$(df --output=pcent /sys/firmware/efi/efivars | tail -n 1 | tr -dc 0-9)
      if [ "$used" -ge 90 ]; then
        notify-send --urgency=critical "efivars ''${used}% full" \
          "Power off fully to let the firmware reclaim NVRAM space."
      fi
    '';
  };
  systemd.user.timers.efivars-usage = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnStartupSec = "5min";
      OnUnitActiveSec = "1d";
    };
  };
}
