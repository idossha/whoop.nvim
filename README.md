# whoop.nvim

A Neovim plugin for integrating WHOOP fitness data directly into your development environment.

## Overview

whoop.nvim provides seamless access to your WHOOP recovery, sleep, and workout data without leaving Neovim. View your physiological metrics through an elegant terminal interface designed for developers.

## Features

- **Interactive Dashboard**: Visualize recovery scores, sleep metrics, and recent workouts
- **Real-time Data**: Direct integration with WHOOP API v2
- **Secure Authentication**: OAuth 2.0 with local token storage
- **Configurable Refresh**: Automatic and manual data updates
- **Vim-native Interface**: Keyboard-driven navigation with familiar motions

## Requirements

- Neovim 0.8+
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- WHOOP membership with developer API access

## Installation

### lazy.nvim

```lua
{
  "idossha/whoop.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("whoop").setup({
      client_id = vim.env.WHOOP_CLIENT_ID,
      client_secret = vim.env.WHOOP_CLIENT_SECRET,
    })
  end,
}
```

### packer.nvim

```lua
use {
  "idossha/whoop.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("whoop").setup({
      client_id = vim.env.WHOOP_CLIENT_ID,
      client_secret = vim.env.WHOOP_CLIENT_SECRET,
    })
  end,
}
```

## Configuration

```lua
require("whoop").setup({
  -- API credentials (required)
  client_id = os.getenv("WHOOP_CLIENT_ID"),
  client_secret = os.getenv("WHOOP_CLIENT_SECRET"),
  
  -- Data refresh settings
  refresh_interval = 3600,    -- seconds
  auto_refresh = true,
  default_days = 7,           -- days of historical data
  
  -- UI preferences
  theme = "auto",             -- "light", "dark", or "auto"
  show_trends = true,
  
  -- Key mappings
  mappings = {
    dashboard = "<leader>wd",
    refresh = "<leader>wr",
    sync = "<leader>ws",
  },
})
```

### Environment Variables

For security, store credentials in environment variables:

```bash
# Add to ~/.bashrc, ~/.zshrc, or similar
export WHOOP_CLIENT_ID="your_client_id"
export WHOOP_CLIENT_SECRET="your_client_secret"
```

Obtain credentials from the [WHOOP Developer Dashboard](https://developer-dashboard.whoop.com).

## Commands

| Command | Description |
|---------|-------------|
| `:WhoopDashboard` | Open fitness dashboard |
| `:WhoopRefresh` | Force data refresh |
| `:WhoopAuth` | Authenticate with WHOOP |
| `:WhoopTest` | Test API connectivity |
| `:WhoopClearAuth` | Clear authentication data |

## Usage

1. **Initial Setup**: Run `:WhoopAuth` to authenticate with WHOOP
2. **View Dashboard**: Press `<leader>wd` or run `:WhoopDashboard`
3. **Refresh Data**: Press `r` in dashboard or run `:WhoopRefresh`
4. **Navigate**: Use standard Vim motions to navigate

### Dashboard Controls

- `r` — Refresh data
- `q` / `<Esc>` — Close dashboard

## Data Display

### Recovery
- Recovery score percentage with visual indicator
- Resting heart rate
- Heart rate variability (HRV)

### Sleep
- Total sleep duration
- Sleep efficiency percentage

### Workouts
- Recent activities with strain scores
- Up to 3 most recent workouts displayed

## Troubleshooting

### API Error: HTTP 401
Your access token has expired. Run `:WhoopAuth` to re-authenticate.

### No Data Available
Ensure you have:
1. Valid WHOOP membership
2. Recent WHOOP device sync
3. Active internet connection

### Commands Not Found
Verify the plugin loaded correctly:
```vim
:checkhealth whoop
```

## Privacy

whoop.nvim stores all data locally on your device. No personal information is transmitted to third parties except authenticated requests to the WHOOP API.

See [PRIVACY.md](PRIVACY.md) for details.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome. Please submit issues and pull requests via GitHub.

## Acknowledgments

- WHOOP for providing the Developer API
- Contributors to plenary.nvim and nui.nvim
