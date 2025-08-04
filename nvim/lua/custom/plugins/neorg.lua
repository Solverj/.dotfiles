return {
  'nvim-neorg/neorg',
  build = ':Neorg sync-parsers',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('neorg').setup {
      load = {
        ['core.defaults'] = {}, -- Loads default behaviour
        ['core.concealer'] = {}, -- Adds pretty icons to your documents
        ['core.dirman'] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              notes = '~/notes',
              todo = '̃~/todo',
            },
          },
        },
      },
    }
  end,
  keys = {
    { '<leader>no', '<cmd>Neorg index<cr>', desc = 'Open Neorg Index' },
    { '<leader>nn', '<cmd>Neorg new note<cr>', desc = 'Create New Note' },
    { '<leader>nq', '<cmd>Neorg query<cr>', desc = 'Run Neorg Query' },
    { '<leader>nr', '<cmd>Neorg return<cr>', desc = 'Return to code' },
    { '<leader>nw', '<cmd>Neorg workspace notes<cr>', desc = 'Switch to Notes Workspace' },
    { '<leader>nto', '<cmd>Neorg workspace todo<cr>', desc = 'Switch to Todo Workspace' },
  },
}
