{ ... }: {
  plugins.telescope = {
    enable = true;
    keymaps = {
      "<C-p>" = {
        action = "git_files";
        options = {
          desc = "Telescope Git Files";
        };
      };
      "<leader>gs" = {
        action = "git_status";
        options = {
          desc = "Telescope Git Status";
        };
      };
      "<leader>fg" = "live_grep";
      "<leader>ff" = "find_files";
      "<leader>fb" = "buffers";
      "<leader>fs" = "grep_string";
      "<leader>fr" = {
        action = "resume";
        options = {
          desc = "Resume live grep";
          noremap = true;
          silent = true;
        };
      };
    };
    settings = {
      pickers = {
        grep_string = {
          initial_mode = "normal";
        };
        resume = {
          initial_mode = "normal";
        };
        git_status = {
          initial_mode = "normal";
        };
      };
      defaults = {
        mappings = {
          n = {
            "q" = {
              __raw = "require('telescope.actions').close";
            };
            "<C-y>" = {
              __raw = "require('telescope.actions.layout').toggle_preview";
            };
          };
          i = {
            "<C-j>" = {
              __raw = "require('telescope.actions').move_selection_next";
            };
            "<C-k>" = {
              __raw = "require('telescope.actions').move_selection_previous";
            };
          };
        };
      };
    };
  };
}
