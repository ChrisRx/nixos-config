local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local lspconfigs = require("lspconfig")
local util = require "lspconfig/util"

lspconfigs.rust_analyzer.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"rust"},
  root_dir = util.root_pattern("Cargo.toml"),
  settings = {
    ['rust_analyzer'] = {
      cargo = {
        allFeatures = true,
      },
    },
  },
})


require("lspconfig").nixd.setup({
    cmd = { "nixd" },
    settings = {
        nixd = {
            nixpkgs = {
                -- For flake.
                -- This expression will be interpreted as "nixpkgs" toplevel
                -- Nixd provides package, lib completion/information from it.
                -- Resource Usage: Entries are lazily evaluated, entire nixpkgs takes 200~300MB for just "names".
                -- Package documentation, versions, are evaluated by-need.
                expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
            },
            formatting = {
                command = { "nixfmt" }, -- or nixfmt or nixpkgs-fmt
            },
            options = {
                nixos = {
                    expr = "let flake = builtins.getFlake(toString ./.); in flake.nixosConfigurations.fw13.options",
                },
                home_manager = {
                    expr = 'let flake = builtins.getFlake(toString ./.); in flake.nixosConfigurations.fw13.options.home-manager.users.type.getSubOptions []',
                },
            },
        },
    },
})

-- why doesn't this work?
-- vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.nix" }, callback = vim.lsp.buf.format })
vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.nix" },
  callback = function (_)
    vim.lsp.buf.format()
  end
})

lspconfigs.gopls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = {"gopls"},
  cmd_env = {
    GOFLAGS = "-tags=test,e2e_test,integration_test,acceptance_test",
  },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = util.root_pattern("go.work", "go.mod", ".git"),
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
}

lspconfigs.golangci_lint_ls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "go" },
}

lspconfigs.templ.setup {
  on_attach = function(client, _)
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
  end,
  capabilities = capabilities,
  cmd = { "/home/chris/.local/share/nvim/mason/bin/templ", "lsp",  "-http=localhost:7474", "-log=/home/chris/templ_ls.log"},
  -- root_dir = lspconfigs.util.root_pattern("go.mod", ".git")
  -- root_dir = "/home/chris/.local/share/nvim/mason/bin",
  filetypes = { "templ" },
  root_dir = lspconfigs.util.root_pattern("go.mod", ".git"),
}
vim.filetype.add({ extension = { templ = "templ" } })
-- vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = vim.lsp.buf.format })

vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" },
  callback = function (_)
    vim.lsp.buf.format()
  end
})

lspconfigs.html.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "html", "templ" },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "templ",
  callback = function()
    vim.bo.commentstring = "// %s"
  end,
})
