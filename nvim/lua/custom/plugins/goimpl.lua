return {
  -- better plugin for using goimpl
  "edolphin-ydf/goimpl.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-lua/popup.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  ft = "go",
  config = function()
    require("telescope").load_extension("goimpl")
  end,
  build = function()
    vim.cmd [[silent! GoInstallDeps]]
  end,
  keys = function()
    vim.api.nvim_set_keymap(
      "n",
      "<leader>im",
      [[<cmd>lua require'telescope'.extensions.goimpl.goimpl{}<CR>]],
      { noremap = true, silent = true }
    )
  end,
}
