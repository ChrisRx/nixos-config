{ pkgs, inputs, username, host, ... }: {
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  nix.settings.allowed-users = [ "${username}" ];

  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    sharedModules = [ inputs.nixvim.homeModules.nixvim ];
    users.${username} = {
      imports = [ ../../home ];

      home.sessionVariables = {
        HISTSIZE = 100000;
        SAVEHIST = 100000;
      };
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "25.11";
      programs.home-manager.enable = true;
    };
  };
}
