return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    lsp = {
      progress = {
        enabled = true,
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
      signature = {
        enabled = true,
        auto_open = {
          enabled = true,
          trigger = true,
        },
      },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      lsp_doc_border = true,
    },
    routes = {
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
    },
  },
  config = function(_, opts)
    require("noice").setup(opts)
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    {
      "rcarriga/nvim-notify",
      opts = {
        background_colour = "#1e1e2e",
        timeout = 3000,
      },
      config = function(_, notify_opts)
        local notify = require("notify")
        notify.setup(notify_opts)
        vim.notify = notify
      end,
    },
  },
}
