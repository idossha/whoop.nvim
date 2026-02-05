local M = {}

local config = require("whoop.config").config
local Popup = require("nui.popup")
local Input = require("nui.input")

local config_popup = nil

function M.open()
  if config_popup then
    config_popup:unmount()
    config_popup = nil
  end

  config_popup = Popup({
    position = "50%",
    size = {
      width = 60,
      height = 20,
    },
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Whoop Configuration ",
        top_align = "center",
      },
    },
    win_options = {
      wrap = false,
    },
  })

  config_popup:mount()

  local lines = {
    "",
    "  Current Configuration:",
    "",
    string.format("  Client ID: %s", config.client_id and "***" or "Not set"),
    string.format("  Client Secret: %s", config.client_secret and "***" or "Not set"),
    string.format("  Auto Refresh: %s", config.auto_refresh and "Enabled" or "Disabled"),
    string.format("  Refresh Interval: %d seconds", config.refresh_interval or 3600),
    string.format("  Default Days: %d", config.default_days or 7),
    string.format("  Theme: %s", config.theme or "auto"),
    "",
    "  Key Mappings:",
  }

  if config.mappings then
    for cmd, mapping in pairs(config.mappings) do
      table.insert(lines, string.format("    %s: %s", cmd, mapping))
    end
  end

  table.insert(lines, "")
  table.insert(lines, "  Press 'q' to close")

  vim.api.nvim_buf_set_lines(config_popup.bufnr, 0, -1, false, lines)

  vim.api.nvim_buf_set_keymap(config_popup.bufnr, "n", "q", "<cmd>lua require('whoop.ui.config').close()<cr>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(config_popup.bufnr, "n", "<esc>", "<cmd>lua require('whoop.ui.config').close()<cr>", { noremap = true, silent = true })

  vim.api.nvim_win_set_option(config_popup.winid, "cursorline", false)
end

function M.close()
  if config_popup then
    config_popup:unmount()
    config_popup = nil
  end
end

return M
