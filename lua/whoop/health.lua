local M = {}

function M.check()
  vim.health.start("whoop.nvim")

  -- Check dependencies
  local has_plenary = pcall(require, "plenary")
  local has_nui = pcall(require, "nui")

  if has_plenary then
    vim.health.ok("plenary.nvim is installed")
  else
    vim.health.error("plenary.nvim is required but not installed")
  end

  if has_nui then
    vim.health.ok("nui.nvim is installed")
  else
    vim.health.error("nui.nvim is required but not installed")
  end

  -- Check config
  local config_ok, config_module = pcall(require, "whoop.config")
  if config_ok and config_module.config then
    local config = config_module.config

    if config.client_id then
      vim.health.ok("Client ID is configured")
    else
      vim.health.error("Client ID is not configured")
      vim.health.info("Set WHOOP_CLIENT_ID environment variable")
    end

    if config.client_secret then
      vim.health.ok("Client Secret is configured")
    else
      vim.health.error("Client Secret is not configured")
      vim.health.info("Set WHOOP_CLIENT_SECRET environment variable")
    end
  else
    vim.health.error("whoop.nvim config module not loaded")
  end

  -- Check if authenticated
  local storage_ok, storage = pcall(require, "whoop.storage")
  if storage_ok then
    local tokens = storage.load_tokens()
    if tokens and tokens.access_token then
      vim.health.ok("Authenticated with Whoop")
      if tokens.expires_at then
        local time_left = tokens.expires_at - os.time()
        if time_left > 0 then
          vim.health.info(string.format("Token expires in %d minutes", math.floor(time_left / 60)))
        else
          vim.health.warn("Token has expired, will refresh on next use")
        end
      end
    else
      vim.health.warn("Not authenticated with Whoop")
      vim.health.info("Run :WhoopAuth to authenticate")
    end
  end
end

return M
