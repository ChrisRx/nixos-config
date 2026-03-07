{ ... }: {
  programs.nixvim = {
    plugins.telescope = {
      enable = true;
      keymaps = {
        "<C-p>" = {
          action = "git_files";
          options = { desc = "Telescope Git Files"; };
        };
        "<leader>fg" = "live_grep";
        "<leader>ff" = "find_files";
      };
      settings = {
        mappings = {
          n = {
            "<leader>ff" = {
              __raw = "require('telescope.builtin').find_files";
            };
            "<leader>fg" = {
              __raw = "require('telescope.builtin').live_grep";
            };
            "<leader>fb" = { __raw = "require('telescope.builtin').buffers"; };
          };
          # i = {
          #   "<A-j>" = {
          #     __raw = "require('telescope.actions').move_selection_next";
          #   };
          #   "<A-k>" = {
          #     __raw = "require('telescope.actions').move_selection_previous";
          #   };
          # };
        };
      };
    };
  };
}
# return {
#   defaults = {
#     prompt_prefix = "   ",
#     selection_caret = " ",
#     entry_prefix = " ",
#     sorting_strategy = "ascending",
#     layout_config = {
#       horizontal = {
#         prompt_position = "top",
#         preview_width = 0.55,
#       },
#       width = 0.87,
#       height = 0.80,
#     },
#     mappings = {
#       n = { ["q"] = require("telescope.actions").close },
#     },
#   },
#
#   extensions_list = { "themes", "terms" },
#   extensions = {},
# }
