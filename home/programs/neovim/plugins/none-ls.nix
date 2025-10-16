{ ... }: {
  programs.nixvim = {
    plugins = {
      none-ls = {
        enable = true;

        settings = {
          on_attach = ''
            function(client, bufnr)
              if client.supports_method("textDocument/formatting") then
                vim.api.nvim_clear_autocmds({
                  group = augroup,
                  buffer = bufnr,
                })
                vim.api.nvim_create_autocmd("BufWritePre", {
                  group = augroup,
                  buffer = bufnr,
                  callback = function()
                    vim.lsp.buf.format({ bufnr = bufnr })
                  end,
                })
              end
            end
          '';
        };
        sources = {
          diagnostics = { golangci_lint.enable = true; };
          formatting = {
            gofmt.enable = true;
            goimports.enable = true;
            nixfmt.enable = true;
            shellharden.enable = true;
            shfmt.enable = true;
          };
        };
      };
    };
  };
}
# "gofumpt",
# "goimports",
# "goimports-reviser",
# "golines",
# "gopls",
# "rust-analyzer",
# "golangci-lint",
# "golangci-lint-langserver",
# "lua-language-server",
# "templ",
# "html-lsp",
# -- "htmx-lsp",
# "tailwindcss-language-server",
