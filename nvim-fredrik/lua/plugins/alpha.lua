return {
  "goolord/alpha-nvim",
  dependencies = {
    {
      "echasnovski/mini.indentscope",
      opts = function()
        -- disable indentation scope for the current ("alpha" filetype) buffer
        vim.cmd([[
        autocmd Filetype alpha lua vim.b.miniindentscope_disable = true
      ]])
      end,
    },
  },
  lazy = true,
  event = "VimEnter",
  opts = function()
    require("alpha")
    require("alpha.term")
    local dashboard = require("alpha.themes.dashboard")
    local logo = [[

   ▄▄▄▄▀ ▄  █ ▄█    ▄▄▄▄▄       ▄█    ▄▄▄▄▄       ▄████  ▄█    ▄   ▄███▄   
▀▀▀ █   █   █ ██   █     ▀▄     ██   █     ▀▄     █▀   ▀ ██     █  █▀   ▀  
    █   ██▀▀█ ██ ▄  ▀▀▀▀▄       ██ ▄  ▀▀▀▀▄       █▀▀    ██ ██   █ ██▄▄    
   █    █   █ ▐█  ▀▄▄▄▄▀        ▐█  ▀▄▄▄▄▀        █      ▐█ █ █  █ █▄   ▄▀ 
  ▀        █   ▐                 ▐                 █      ▐ █  █ █ ▀███▀   
          ▀                                         ▀       █   ██         

      ]]

    local ansiArt = "gopher"
    local function getGreeting(name)
      local tableTime = os.date("*t")
      local datetime = os.date(" %Y-%m-%d   %H:%M:%S")
      local hour = tableTime.hour
      local greetingsTable = {
        [1] = "  Sleep well",
        [2] = "  Good morning",
        [3] = "  Good afternoon",
        [4] = "  Good evening",
        [5] = "󰖔  Good night",
      }
      local greetingIndex = 0
      if hour == 23 or hour < 7 then
        greetingIndex = 1
        ansiArt = "thisisfine"
      elseif hour < 12 then
        greetingIndex = 2
        ansiArt = "gopher"
      elseif hour >= 12 and hour < 18 then
        greetingIndex = 3
        ansiArt = "gopher"
      elseif hour >= 18 and hour < 21 then
        greetingIndex = 4
        ansiArt = "unicorn"
      elseif hour >= 21 then
        greetingIndex = 5
        ansiArt = "thisisfine"
      end
      return "\t" .. datetime .. "\t" .. greetingsTable[greetingIndex] .. ", " .. name
    end

    local userName = "Fredrik"
    local greeting = getGreeting(userName)
    local width = 46
    local height = 25

    -- dashboard.section.header.val = vim.split(logo .. "\n" .. greeting, "\n")
    dashboard.section.header.val = greeting
    dashboard.section.header.opts.hl = "DashboardHeader"
    dashboard.section.header.opts.position = "center"
    dashboard.section.terminal.command = "cat | $DOTFILES/nvim-fredrik/ansi/" .. ansiArt .. ".sh"
    dashboard.section.terminal.width = width
    dashboard.section.terminal.height = height
    dashboard.section.terminal.opts.redraw = true

    dashboard.section.buttons.val = {
      dashboard.button("s", " " .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
      -- dashboard.button("s", " " .. " Restore Session", ":source Session.vim<CR>"),
      dashboard.button("f", " " .. " Recent files", ":Telescope oldfiles<CR>"),
      dashboard.button("l", " " .. " Update plugins", ":Lazy<CR>"),
      dashboard.button("q", " " .. " Quit", ":qa<CR>"),
    }
    dashboard.config.layout = {
      { type = "padding", val = 1 },
      dashboard.section.terminal,
      { type = "padding", val = 5 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 1 },
      dashboard.section.footer,
    }

    return dashboard
  end,
  config = function(_, opts)
    require("alpha").setup(opts.config)
  end,
}
