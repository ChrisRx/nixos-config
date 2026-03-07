{ ... }: {
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "onedark";
          component_separators = "";
          section_separators = {
            left = "";
            right = "";
          };
        };
        extensions = [ "nvim-tree" ];
      };
    };
  };
}
