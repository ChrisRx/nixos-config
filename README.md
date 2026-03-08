# nixos-config

This repo is my personal NixOS configurations. It is based heavily on Frost-Phoenix's [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config).

## Usage

Upgrade packages and rebuild OS (includes home-manager):

```shell
task upgrade
```

The output of `$(hostname)` is used to pass in which host should be built.

### Modules

```shell
├── 📁 hosts
│   └── 📁 <hostname>
│       ├── ⚙ default.nix
│       └── ⚙ hardware-configuration.nix
└── 📁 modules
    ├── 📁 home  # home-manager modules
    └── 📁 nixos # NixOS modules
```

Modules are separated by types into separate directories: `modules/nixos` and `modules/home` for NixOS and home-manager modules, respectively.

The core NixOS module contains basic configuration values with defaults and can be used by adding to imports:

```nix
imports = [ ../../modules/nixos/core ];
```

Using the GNOME desktop environment only requires importing the NixOS module:

```nix
imports = [ ../../modules/nixos/gnome ];
```

The following imports my entire home-manager configuration:

```nix
imports = [ inputs.home-manager.nixosModules.home-manager ];
home-manager = {
  users.${username} = {
    imports = [ ../../modules/home ];
  }
}
```

My neovim configuration using [nixvim](https://nix-community.github.io/nixvim/) can be used within other installations of home-manager:

```nix
users.${username} = {
  imports = [ ../../modules/home/programs/neovim ];
}
```

## TODO

* More configuration options for NixOS/home-manager
* Add override for hostname in Taskfile.yml
* Better packages options for different sets of home-manager packages
* neovim configuration is still a WIP
  * treesitter grammars are not installing correctly and I need to still run `TSInstall` for some reason
  * some small graphical quirks (spacing on bars)
  * need better tab styling
  * better nvim-tree styling
  * finish Go snippets
  * telescope configuration still needs some work
  * motion repeat isn't working for some reason (it brings up the menu, despite noremap)
* hyprland module is a placeholder and needs a lot of work
* checkout cosmic again when stuff gets more fleshed out
  * three-finger swipe for workspace switch
  * fprint behavior on greeter is broken in current version
