local Pickers = require('telescope.pickers')
local Finders = require('telescope.finders')
local Conf = require('telescope.config').values
local Path = require('plenary.path')
local Make_entry = require "telescope.make_entry"

local M = {}

local function get_dependencies(go_mod_path)
  local deps = {}
  local go_mod = Path:new(go_mod_path)

  if not go_mod:exists() then
    return nil, "go.mod not found"
  end
  local in_require_block = false
  for line in go_mod:iter() do
    -- Detect the start of a 'require' block
    if line:match("^%s*require%s*%(") then
      in_require_block = true
    elseif in_require_block and line:match("^%s*%)") then
      -- End of the 'require' block
      in_require_block = false
    elseif in_require_block then
      -- Extract dependencies inside a block (with version)
      local dep, version = line:match("^%s*([%w%.%-_/!]+)%s+v?([%d%.%-]+%-?[a-f0-9]*)")
      if dep and version then
        -- Convert both dep and version to lowercase before storing them
        dep = string.lower(dep)
        version = string.lower(version)
        table.insert(deps, { dep = dep, version = version })
      end
    elseif line:match("^%s*require%s+[%w%.%-_/!]+%s+v?[%d%.%-]+") then
      -- Extract dependency outside a block (with version)
      local dep, version = line:match("^%s*require%s+([%w%.%-_/!]+)%s+v?([%d%.%-]+%-?[a-f0-9]*)")
      if dep and version then
        -- Convert both dep and version to lowercase before storing them
        dep = string.lower(dep)
        version = string.lower(version)
        table.insert(deps, { dep = dep, version = version })
      end
    end
  end
  return deps, nil
end

M.search_dependencies = function(opts)
  opts = opts or {}
  local cwd = vim.fn.getcwd()
  local go_mod_path = cwd .. "/go.mod"
  local gomodcache = vim.fn.getenv("GOMODCACHE")
  if gomodcache == vim.NIL then
    gomodcache = vim.fn.expand("~") .. "/go/pkg/mod" -- Default fallback path
  end

  if not vim.loop.fs_stat(go_mod_path) then
    vim.notify("go.mod not found in " .. cwd, vim.log.levels.ERROR)
    return
  end

  local deps, err = get_dependencies(go_mod_path)
  if not deps then
    vim.notify("Error parsing go.mod: " .. err, vim.log.levels.ERROR)
    return
  end

  local rg_results = {}
  for _, dep_info in ipairs(deps) do
    local dep = dep_info.dep
    local version = dep_info.version
    -- If dep is nil, skip to the next iteration
    if dep == nil then
      goto continue
    end

    -- Construct dep_path for the module name
    local dep_path = gomodcache .. "/" .. dep
    dep_path = dep_path .. "@v" .. version

    -- Add the dep_path without '!' (original path)
    if vim.loop.fs_stat(dep_path) then
      -- print("dep path without '!'", dep_path)
      local escaped_dep_path = vim.fn.shellescape(dep_path)
      local command =
          "rg --smart-case --color=never --no-heading --with-filename --line-number --column --glob '*.go' . " ..
          escaped_dep_path
      print("command", command)
      local handle = io.popen(command, "r")
      if not handle then
        vim.notify("Error running rg command", vim.log.levels.ERROR)
        goto continue
      end
      local result = handle:read("*a")
      print("poop")
      print("result", result)
      handle:close()
      for line in result:gmatch("[^\r\n]+") do
        print("line", line)
        table.insert(rg_results, line)
      end
    else
      -- Check for dep_path with '!' in front of the folder (modified path)
      -- //INFO: i'll do this later for private repos
      -- local dep_path_with_bang = dep_path:gsub("(/[%w%-_]+%.[%w%-_]+)/", "/!%1/", 1)
      -- -- print("dep path with '!", dep_path_with_bang)
      -- if vim.loop.fs_stat(dep_path_with_bang) then
      --   -- print("dep_path with '!'", dep_path_with_bang)
      --   table.insert(rg_commands, {
      --     "rg", "--smart-case", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column",
      --     dep_path_with_bang
      --   })
      -- end
    end
    ::continue::
  end

  -- Log the commands for debugging
  print(rg_results)

  -- Create the picker with the commands
  Pickers.new(opts, {

    prompt_title = "Go Dependencies",
    finder = Finders.new_table({
      results = rg_results,
      entry_maker = function(line)
        return {
          value = line,
          ordinal = line,
          display = line,
        }
      end,
    }),
    -- finder = Finders.new_job(rg_commands, Make_entry.gen_from_vimgrep(opts)),
    sorter = require("telescope.sorters").get_fuzzy_file(opts),
  }):find()
end
return M
