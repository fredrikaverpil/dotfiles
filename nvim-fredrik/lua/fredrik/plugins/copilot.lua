return {
  {
    "zbirenbaum/copilot.lua",
    lazy = true,
    commit = "5a8fdd34bb67eadc3f69e46870db0bed0cc9841c",
    event = "InsertEnter",
    enabled = true,
    dependencies = {
      {
        "copilotlsp-nvim/copilot-lsp",
        enabled = true,
        dependencies = {
          {
            "mason-org/mason.nvim",
            opts = function(_, opts)
              opts.ensure_installed = opts.ensure_installed or {}
              vim.list_extend(opts.ensure_installed, { "copilot-language-server" })
            end,
          },
        },
        init = function()
          vim.g.copilot_nes_debounce = 500
          vim.lsp.enable("copilot_ls")
          vim.keymap.set("n", "<tab>", function()
            local bufnr = vim.api.nvim_get_current_buf()
            local state = vim.b[bufnr].nes_state
            if state then
              -- Try to jump to the start of the suggestion edit.
              -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
              local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
                or (
                  require("copilot-lsp.nes").apply_pending_nes()
                  and require("copilot-lsp.nes").walk_cursor_end_edit()
                )
              return nil
            else
              -- Resolving the terminal's inability to distinguish between `TAB` and `<C-i>` in normal mode
              return "<C-i>"
            end
          end, { desc = "Accept Copilot NES suggestion", expr = true })
          -- Clear copilot suggestion with Esc if visible, otherwise preserve default Esc behavior
          vim.keymap.set("n", "<esc>", function()
            if not require("copilot-lsp.nes").clear() then
              -- fallback to other functionality
            end
          end, { desc = "Clear Copilot suggestion or fallback" })
        end,
      },
      {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function(_, opts)
          local function codepilot()
            local icon = require("fredrik.utils.icons").icons.kinds.Copilot
            return icon
          end

          local colors = {
            -- statuses NOT supported by copilot.lua (see `require("copilot").api.status`)
            ["Offline"] = require("fredrik.utils.colors").fgcolor("Comment"),
            -- statuses supported by copilot.lua
            [""] = require("fredrik.utils.colors").fgcolor("Special"),
            ["InProgress"] = require("fredrik.utils.colors").fgcolor("DiagnosticWarning"),
            ["Normal"] = require("fredrik.utils.colors").fgcolor("DiagnosticOk"),
            ["Warning"] = require("fredrik.utils.colors").fgcolor("DiagnosticError"),
          }

          opts.copilot = {
            lualine_component = {
              codepilot,
              color = function()
                if not package.loaded["copilot"] or vim.g.custom_copilot_status == "disabled" then
                  -- offline
                  return colors["Offline"]
                else
                  -- online
                  local status = require("copilot.api").status
                  if status.data.message ~= "" then
                    -- NOTE: could potentially do something based on status.data.message too.
                    vim.notify("Copilot message: " .. vim.inspect(status.data.message))
                  end
                  return colors[status.data.status]
                end
              end,
            },
          }
        end,
      },
    },
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      copilot_model = "gpt-4o-copilot",
      panel = {
        enabled = true,
        auto_refresh = true,
      },
      suggestion = {
        -- use the built-in keymapping for "accept" (<M-l>)
        enabled = true,
        auto_trigger = true,
      },
      filetypes = {
        sh = function()
          if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "^%.env.*") then
            -- disable for .env files
            return false
          end
          return true
        end,
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)

      -- Make sure not to enable copilot in private projects
      require("fredrik.utils.private").toggle_copilot()
    end,
    keys = require("fredrik.config.keymaps").setup_copilot_keymaps(),
  },
}
