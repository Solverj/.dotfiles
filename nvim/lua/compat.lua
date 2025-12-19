-- Compatibility helpers for deprecated APIs removed in newer Neovim versions.

-- Provide a shim for vim.tbl_flatten that delegates to vim.iter to avoid the
-- runtime deprecation warning while keeping legacy plugins working.
if type(vim.tbl_flatten) == 'function' and type(vim.iter) == 'function' then
  vim.tbl_flatten = function(t)
    return vim.iter(t):flatten():totable()
  end
end

-- Allow legacy vim.validate(spec) calls without triggering a warning by
-- translating them to the new signature eagerly.
if type(vim.validate) == 'function' then
  local new_validate = vim.validate
  vim.validate = function(name, value, validator, optional, message)
    if type(name) == 'table' then
      local keys = {}
      for key in pairs(name) do
        keys[#keys + 1] = key
      end
      table.sort(keys)
      for _, key in ipairs(keys) do
        local spec = name[key]
        if type(spec) ~= 'table' then
          error(string.format('opt[%s]: expected table, got %s', key, type(spec)), 2)
        end
        local arg_value, arg_validator = spec[1], spec[2]
        local third = spec[3]
        local optional_entry = third == true
        local msg = type(third) == 'string' and third or nil
        if not (optional_entry and arg_value == nil) then
          local ok, err = pcall(new_validate, key, arg_value, arg_validator, optional_entry, msg)
          if not ok then
            error(err, 2)
          end
        end
      end
      return
    end
    return new_validate(name, value, validator, optional, message)
  end
end

-- Alias renamed modules that some plugins still `require`.
package.preload['nvim-treesitter.configs'] = package.preload['nvim-treesitter.configs']
  or function()
    return require('nvim-treesitter.config')
  end

package.preload['nvim-treesitter.ts_utils'] = package.preload['nvim-treesitter.ts_utils']
  or function()
    local ok, mod = pcall(require, 'vim.treesitter.ts_utils')
    if ok then
      return mod
    end
    local ts = require('nvim-treesitter')
    local parser_cache = {}
    local M = {}
    function M.get_node_at_cursor(winnr)
      winnr = winnr or vim.api.nvim_get_current_win()
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      local ft = vim.bo[bufnr].filetype
      parser_cache[bufnr] = parser_cache[bufnr]
        or vim.treesitter.get_parser(bufnr, ft, { reuse_tree = true })
      local tree = parser_cache[bufnr]:parse()[1]
      if not tree then
        return
      end
      local node = tree:root()
      local row, col = unpack(vim.api.nvim_win_get_cursor(winnr))
      row = row - 1
      local found = node:named_descendant_for_range(row, col, row, col)
      return found
    end
    return M
  end

return {}
