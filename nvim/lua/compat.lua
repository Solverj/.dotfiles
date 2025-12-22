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

return {}
