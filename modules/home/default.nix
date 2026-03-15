{ config, lib, pkgs, ... }:

let cfg = config.packages;
in {
  imports = [ ./programs ];

  options.packages = builtins.listToAttrs (builtins.map (name: {
    inherit name;
    value = { enable = lib.mkEnableOption "Enable ${name} packages"; };
  }) [
    # categories
    "all"
    "cloud"
    "development"
    "experimental"
    "extra"
    "fonts"
    "utils"
  ]);

  config = {
    home.packages = with pkgs;
      [
        fastfetch
        git
        go-task
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nix-prefetch-scripts
      ] ++ lib.lists.optionals cfg.development.enable or cfg.all.enable [
        protobuf

        go
        golangci-lint
        gotools
        go-tools
        protoc-gen-go
        protoc-gen-go-grpc

        rustup

        mdbook
        slides
        glow

        kubernetes-helm
        kind
        kubectl
        tilt
        cmake

        sqlite
        duckdb
      ] ++ lib.lists.optionals cfg.cloud.enable or cfg.all.enable [
        (google-cloud-sdk.withExtraComponents
          [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
        awscli2
        azure-cli
        terraform
      ] ++ lib.lists.optionals cfg.utils.enable or cfg.all.enable [
        powertop
        entr
        htop
        dig
        gnumake
        unzip
        dust
        jq
      ] ++ lib.lists.optionals cfg.extra.enable or cfg.all.enable [
        google-chrome
        vlc
        gimp
        audacity
        discord
      ] ++ lib.lists.optionals cfg.experimental.enable or cfg.all.enable [
        nodejs
        minio
        minio-client
        renderdoc
        wayland
        fzf
        nixfmt-rfc-style
        html-tidy
        sops
      ] ++ lib.lists.optionals cfg.fonts.enable or cfg.all.enable [
        nerd-fonts."m+"
        nerd-fonts._0xproto
        nerd-fonts._3270
        nerd-fonts.adwaita-mono
        nerd-fonts.agave
        nerd-fonts.anonymice
        nerd-fonts.arimo
        nerd-fonts.atkynson-mono
        nerd-fonts.aurulent-sans-mono
        nerd-fonts.bigblue-terminal
        nerd-fonts.bitstream-vera-sans-mono
        nerd-fonts.blex-mono
        nerd-fonts.caskaydia-cove
        nerd-fonts.caskaydia-mono
        nerd-fonts.code-new-roman
        nerd-fonts.comic-shanns-mono
        nerd-fonts.commit-mono
        nerd-fonts.cousine
        nerd-fonts.daddy-time-mono
        nerd-fonts.dejavu-sans-mono
        nerd-fonts.departure-mono
        nerd-fonts.droid-sans-mono
        nerd-fonts.envy-code-r
        nerd-fonts.fantasque-sans-mono
        nerd-fonts.fira-code
        nerd-fonts.fira-mono
        nerd-fonts.geist-mono
        nerd-fonts.go-mono
        nerd-fonts.gohufont
        nerd-fonts.hack
        nerd-fonts.hasklug
        nerd-fonts.heavy-data
        nerd-fonts.hurmit
        nerd-fonts.im-writing
        nerd-fonts.inconsolata
        nerd-fonts.inconsolata-go
        nerd-fonts.inconsolata-lgc
        nerd-fonts.intone-mono
        nerd-fonts.iosevka
        nerd-fonts.iosevka-term
        nerd-fonts.iosevka-term-slab
        nerd-fonts.lekton
        nerd-fonts.liberation
        nerd-fonts.lilex
        nerd-fonts.martian-mono
        nerd-fonts.meslo-lg
        nerd-fonts.monaspace
        nerd-fonts.monofur
        nerd-fonts.monoid
        nerd-fonts.mononoki
        nerd-fonts.noto
        nerd-fonts.open-dyslexic
        nerd-fonts.overpass
        nerd-fonts.profont
        nerd-fonts.proggy-clean-tt
        nerd-fonts.recursive-mono
        nerd-fonts.roboto-mono
        nerd-fonts.sauce-code-pro
        nerd-fonts.shure-tech-mono
        nerd-fonts.space-mono
        nerd-fonts.symbols-only
        nerd-fonts.terminess-ttf
        nerd-fonts.tinos
        nerd-fonts.ubuntu
        nerd-fonts.ubuntu-mono
        nerd-fonts.ubuntu-sans
        nerd-fonts.victor-mono
        nerd-fonts.zed-mono
      ];
  };
}
