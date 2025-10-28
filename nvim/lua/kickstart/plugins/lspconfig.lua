-- =========================
-- 📦 LSP Configuration
-- =========================
return {
  {
    -- 🧠 Lua LSP for Neovim runtime & plugin development
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    -- 🧰 Main LSP Config
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      { 'williamboman/mason-lspconfig.nvim', opts = {} },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      -- ===========================================
      -- 🧭 On Attach: shared LSP keymaps & features
      -- ===========================================
      local function on_attach(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
        end

        map('grn', vim.lsp.buf.rename, 'Rename')
        map('gra', vim.lsp.buf.code_action, 'Code Action')
        map('grr', require('telescope.builtin').lsp_references, 'References')
        map('grd', require('telescope.builtin').lsp_definitions, 'Definition')
        map('gri', require('telescope.builtin').lsp_implementations, 'Implementation')
        map('grt', require('telescope.builtin').lsp_type_definitions, 'Type Definition')
        map('gO', require('telescope.builtin').lsp_document_symbols, 'Doc Symbols')
        map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace Symbols')
        map('grD', vim.lsp.buf.declaration, 'Declaration')

        -- Highlight references
        local client = vim.lsp.get_client_by_id(vim.lsp.get_active_clients({ bufnr = bufnr })[1].id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = bufnr,
            group = group,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = bufnr,
            group = group,
            callback = vim.lsp.buf.clear_references,
          })
        end

        -- Inlay hints toggle
        if vim.lsp.inlay_hint then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
          map('<leader>th', function()
            local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
            vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
          end, 'Toggle Inlay Hints')
        end
      end

      -- =====================
      -- 🧭 Diagnostic Config
      -- =====================
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(d)
            return d.message
          end,
        },
      }

      -- ======================
      -- ⚙️ LSP Server Settings
      -- ======================
      local servers = {
        gopls = {
          cmd = { 'gopls' },
          filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
          root_markers = { 'go.work', 'go.mod', '.git' },
          settings = {
            gopls = {
              buildFlags = { '-tags=integration' },
              codelenses = {
                generate = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                parameterNames = true,
              },
              analyses = {
                unusedparams = true,
                unusedwrite = true,
                nilness = true,
              },
              gofumpt = true,
              staticcheck = true,
              usePlaceholders = true,
              completeUnimported = true,
              matcher = 'CaseInsensitive',
              experimentalPostfixCompletions = true,
              directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules', '-build', '-out' },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              hint = { enable = true },
              completion = { callSnippet = 'Replace' },
              diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
        tombi = {},
      }

      -- ===================================
      -- 📥 Mason auto install + LSP startup
      -- ===================================
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { 'stylua', 'yamlls', 'gopls' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, config in pairs(servers) do
        config.on_attach = on_attach
        vim.lsp.config(name, config)
      end
    end,
  },
}
