{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, self, ... }@inputs:
    let
      username = "chris";
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        htpc = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/htpc ];
          specialArgs = {
            host = "htpc";
            inherit self inputs username;
          };
        };
      };
      nixosConfigurations = {
        fw13 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/fw13 ];
          specialArgs = {
            host = "fw13";
            inherit self inputs username;
          };
        };
      };
    };
}
