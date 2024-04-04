return {
  {
    -- INFO: Highlight markdown codeblocks in neovim.
    "yaocccc/nvim-hl-mdcodeblock.lua",
    after = 'nvim-treesitter',
    config = function()
      require('hl-mdcodeblock').setup()
    end
  },
  {
    -- INFO: Previous tables in real time.
    "iamcco/markdown-preview.nvim",
  },
  {
    -- INFO: Making tables in MD easier with :EasyTablesCreateNew
    "Myzel394/easytables.nvim",
  }
}
