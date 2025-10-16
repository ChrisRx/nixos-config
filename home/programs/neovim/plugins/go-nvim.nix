{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "go.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "ray-x";
          repo = "go.nvim";
          rev = "2f7cd3a20a2940320d5cad338722601ffa3ce31b";
          hash = "sha256-p6k93OkxKmeCDbMU6wS+YMNaVT7uwDo8mYAK+r9BrIA=";
        };
        doCheck = false;
      })
    ];

    extraConfigLuaPre = ''
      require('go').setup({ luasnip = true; })
    '';
  };
}
