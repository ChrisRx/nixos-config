{ ... }: {
  programs.nixvim = {
    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "onedark";
          component_separators = "";
          # component_separators = { left = '', right = ''},
          section_separators = {
            # left = "";
            left = "";
            right = "";
          };

          # component_separators = {
          #   # left = "";
          #   left = "";
          #   right = "";
          # };
        };
        extensions = [ "nvim-tree" ];
      };
    };
  };
}
