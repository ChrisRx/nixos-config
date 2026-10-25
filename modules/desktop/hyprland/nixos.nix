{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.desktop.hyprland;

  # Compositor and portal both come from nixpkgs-unstable, the same tree
  # ./home.nix builds the plugins against through its `unstable` arg, since a
  # plugin only loads into the exact compositor build it was compiled for.
  # NixOS evaluation has no `unstable` module arg, so this reads the input's
  # legacyPackages directly. Neither package is unfree, so home-manager's
  # allowUnfree instance resolves to the same derivations.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      # nixpkgs' hyprland writes an absolute uwsm path into its
      # hyprland-uwsm.desktop, so gdm's stripped session PATH needs no
      # workaround here.
      package = unstable.hyprland;
      portalPackage = unstable.xdg-desktop-portal-hyprland;
    };
    # This also sets security.pam.services.login.enableGnomeKeyring, which is
    # the definition that matters: gdm-password is `auth substack login`, and
    # the gdm-fingerprint stack gates its own pam_gnome_keyring rule on
    # `login.enableGnomeKeyring`. There is no `gdm` pam service to set it on —
    # the gdm module defines gdm-launch-environment, gdm-password,
    # gdm-autologin and gdm-fingerprint and nothing else, so the
    # security.pam.services.gdm definition that used to sit here only created
    # an /etc/pam.d/gdm that gdm never opens.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.hyprland.enableGnomeKeyring = true;

    # A fingerprint login cannot unlock the login keyring, and no pam setting
    # changes that: the keyring is encrypted with the login password, and
    # pam_gnome_keyring unlocks it with the token pam collected during auth,
    # which fingerprint auth never produces. gdm-fingerprint's one escape hatch
    # is pam_gdm.so, which reads the `user:cryptsetup` key systemd-cryptsetup
    # caches when a luks passphrase is typed at boot; root here is plain ext4,
    # so it finds nothing and falls through. Logging in by password unlocks the
    # keyring as it always did.
    #
    # What the masks below change is only *when* the prompt arrives.
    # gnome-keyring's two autostart entries have their OnlyShowIn commented out
    # in nixpkgs, so they are not gnome-restricted, and uwsm pulls in
    # xdg-desktop-autostart.target as soon as the compositor is up:
    #
    #   09:57:45  Reached target XDG Autostart for session of hyprland.desktop
    #   09:57:45  Starting Certificate and Key Storage...     (--components=pkcs11)
    #   09:57:45  Starting Secret Storage Service...          (--components=secrets)
    #   09:57:46  gcr-prompter: starting password prompt
    #
    # Initializing those components opens the locked keyring, so the prompt
    # lands a second into the session and reads as part of logging in. The gnome
    # session never ran them at all: both entries carry the legacy
    # X-GNOME-Autostart-Phase key, which gnome-session now rejects outright
    # ("gnome-session no longer manages session services"), leaving
    # org.freedesktop.secrets to be d-bus activated later on first real demand.
    # Masking reproduces that, and activation still works because gnome-keyring
    # ships the .service files for both org.freedesktop.secrets and
    # org.gnome.keyring.
    #
    # /etc/systemd/user, where `enable = false` writes its /dev/null symlink,
    # outranks $XDG_RUNTIME_DIR/systemd/generator in the user unit load path, so
    # the mask wins over the generator's own .wants link. The \x2d escapes are
    # what systemd-xdg-autostart-generator names these: see
    # /run/user/$(id -u)/systemd/generator*/.
    systemd.user.units."app-gnome\\x2dkeyring\\x2dsecrets@autostart.service".enable = false;
    systemd.user.units."app-gnome\\x2dkeyring\\x2dpkcs11@autostart.service".enable = false;

    # The gnome desktop module turns these on with mkDefault, and on a host
    # that also runs this session they leak into it. Nautilus d-bus activates
    # localsearch on first launch, which then crawls $HOME for the rest of the
    # session (~470M resident, 1.1G peak), and goa-daemon comes up alongside it.
    # ibus runs from login as the input method. None of it is used here, and
    # since these are system-wide the gnome session on this host loses them
    # too: nautilus search falls back to its unindexed engine and the overview
    # no longer finds files.
    services.gnome.localsearch.enable = false;
    services.gnome.gnome-online-accounts.enable = false;
    i18n.inputMethod.enable = false;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
