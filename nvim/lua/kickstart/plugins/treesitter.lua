return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false, -- upstream no longer supports lazy-loading
    build = ':TSUpdate',
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'go', 'gomod' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
        enable = true,
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    config = function(_, opts)
      local ts = require 'nvim-treesitter'

      local installed = {}
      for _, lang in ipairs(ts.get_installed()) do
        installed[lang] = true
      end

      local available = {}
      for _, lang in ipairs(ts.get_available()) do
        available[lang] = true
      end

      local function install_missing(languages)
        if not languages then
          return
        end
        if type(languages) == 'string' then
          languages = { languages }
        end

        local to_install = {}
        for _, lang in ipairs(languages) do
          if lang ~= '' and available[lang] and not installed[lang] then
            table.insert(to_install, lang)
          end
        end

        if #to_install > 0 then
          ts.install(to_install)
          for _, lang in ipairs(to_install) do
            installed[lang] = true
          end
        end
      end

      install_missing(opts.ensure_installed)

      local indent = opts.indent or {}
      local highlight = opts.highlight or {}
      local indent_enabled = indent.enable ~= false
      local highlight_enabled = highlight.enable ~= false
      local indent_disabled = {}
      for _, lang in ipairs(indent.disable or {}) do
        indent_disabled[lang] = true
      end

      local regex_enabled = {}
      for _, lang in ipairs(highlight.additional_vim_regex_highlighting or {}) do
        regex_enabled[lang] = true
      end

      local group = vim.api.nvim_create_augroup('treesitter-autostart', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          if not ft or ft == '' then
            return
          end

          if highlight_enabled then
            pcall(vim.treesitter.start, args.buf, ft)
            if regex_enabled[ft] then
              vim.bo[args.buf].syntax = 'on'
            end
          end
          if indent_enabled and not indent_disabled[ft] then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          if opts.auto_install ~= false then
            local lang = vim.treesitter.language.get_lang(ft)
            if lang then
              install_missing(lang)
            end
          end
        end,
      })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}
-- vim: ts=2 sts=2 sw=2 et
