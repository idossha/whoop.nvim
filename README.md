# Whoop.nvim

A Neovim plugin for displaying Whoop fitness tracker data in a TUI format.

## Features

- Display recovery scores, sleep data, workouts, and daily cycles
- OAuth 2.0 authentication with secure token storage
- Configurable data refresh intervals
- Interactive dashboard with vim motions
- Text-based visualizations and charts

## Requirements

- Neovim 0.7+
- plenary.nvim
- nui.nvim

## Installation

Using lazy.nvim:
```lua
{
  "yourname/whoop.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim"
  },
  config = function()
    require("whoop").setup({
      client_id = "your_client_id",
      client_secret = "your_client_secret"
    })
  end
}
```

## Configuration

```lua
require('whoop').setup({
  -- API configuration
  client_id = "your_client_id",
  client_secret = "your_client_secret",
  
  -- Refresh settings
  refresh_interval = 3600, -- 1 hour in seconds
  auto_refresh = true,
  
  -- UI settings
  theme = "auto", -- "light", "dark", "auto"
  show_trends = true,
  default_days = 7,
  
  -- Key mappings
  mappings = {
    dashboard = "<leader>wd",
    refresh = "<leader>wr",
    sync = "<leader>ws"
  }
})
```

## Commands

- `:WhoopDashboard` - Open main dashboard
- `:WhoopRefresh` - Force refresh data
- `:WhoopAuth` - Re-authenticate
- `:WhoopConfig` - Open configuration

## License

MIT