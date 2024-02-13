return {
  "olexsmir/gopher.nvim",
  ft = "go",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-lua/popup.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function(_, opts)
    require("gopher").setup(opts)
  end,
  build = function()
    vim.cmd([[silent! GoInstallDeps]])
  end,
  keys = {
    {
      "<leader>ce", "<cmd>GoIfErr<CR>", "GoIfErr",
    },
  }
}
