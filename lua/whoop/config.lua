local M = {}

local default_config = {
  client_id = nil,
  client_secret = nil,
  
  refresh_interval = 3600,
  auto_refresh = true,
  
  theme = "auto",
  show_trends = true,
  default_days = 7,
  
  mappings = {
    dashboard = "<leader>wd",
    refresh = "<leader>wr",
    sync = "<leader>ws"
  }
}

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
  
  if not M.config.client_id or not M.config.client_secret then
    vim.notify("whoop.nvim: client_id and client_secret are required", vim.log.levels.ERROR)
    return
  end
  
  vim.api.nvim_create_user_command("WhoopDashboard", function()
    require("whoop.ui.dashboard").open()
  end, {})
  
  vim.api.nvim_create_user_command("WhoopRefresh", function()
    require("whoop.api").refresh_all_data()
  end, {})
  
  vim.api.nvim_create_user_command("WhoopAuth", function()
    require("whoop.auth").authenticate()
  end, {})
  
  vim.api.nvim_create_user_command("WhoopConfig", function()
    require("whoop.ui.config").open()
  end, {})
  
  vim.api.nvim_create_user_command("WhoopTest", function()
    require("whoop.api").test_api()
  end, {})
  
  vim.api.nvim_create_user_command("WhoopClearAuth", function()
    require("whoop.api").clear_auth()
  end, {})
  
  if M.config.mappings then
    for cmd, mapping in pairs(M.config.mappings) do
      vim.keymap.set("n", mapping, function()
        if cmd == "dashboard" then
          require("whoop.ui.dashboard").open()
        elseif cmd == "refresh" then
          require("whoop.api").refresh_all_data()
        elseif cmd == "sync" then
          require("whoop.auth").authenticate()
        end
      end, { desc = "Whoop: " .. cmd })
    end
  end
end

return M