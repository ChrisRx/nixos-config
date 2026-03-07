{ pkgs, ... }:
{
  home.packages = with pkgs; [ git-credential-manager ];

  programs.git = {
    enable = true;

    ignores = [ "_taynes" ];

    settings = {
      aliases = {
        "af" = "!git fetch origin && git rebase origin/main --autostash";
      };
      pull = {
        ff = "only";
      };
      credential = {
        credentialStore = "cache";
        cacheOptions = "--timeout=86400";
        "https://github.com".username = "ChrisRx";
        helper = "manager";
      };
      user = {
        name = "Chris Marshall";
        email = "chris@couch.life";
      };
      url = {
        "https://" = {
          insteadOf = "git://";
        };
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
