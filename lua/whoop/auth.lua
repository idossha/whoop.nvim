local M = {}

local config_module = require("whoop.config")
local storage = require("whoop.storage")
local http = require("whoop.http")

local WHOOP_AUTH_URL = "https://api.prod.whoop.com/oauth/oauth2/auth"
local WHOOP_TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token"
local REDIRECT_URI = "http://localhost:8080/callback"

-- Store the state for verification
local auth_state = nil

-- Helper to get config dynamically
local function get_config()
  return config_module.config
end

-- Generate a random state string (at least 8 chars)
local function generate_state()
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local length = 16
  local result = {}
  for i = 1, length do
    local idx = math.random(1, #chars)
    table.insert(result, chars:sub(idx, idx))
  end
  return table.concat(result)
end

function M.authenticate()
  local config = get_config()

  if not config.client_id or not config.client_secret then
    vim.notify("whoop.nvim: client_id and client_secret not configured. Run :checkhealth whoop", vim.log.levels.ERROR)
    return
  end

  -- Generate and store state for verification
  auth_state = generate_state()

  local server = vim.uv.new_tcp()
  if not server then
    vim.notify("Failed to create auth server", vim.log.levels.ERROR)
    return
  end

  server:bind("127.0.0.1", 8080)
  server:listen(1, function(err)
    if err then
      vim.schedule(function()
        vim.notify("Auth server error: " .. tostring(err), vim.log.levels.ERROR)
      end)
      return
    end

    local client = vim.uv.new_tcp()
    server:accept(client)

    client:read_start(function(read_err, data)
      if read_err then
        vim.schedule(function()
          vim.notify("Client read error: " .. tostring(read_err), vim.log.levels.ERROR)
        end)
        return
      end

      if data then
        -- Check for error in callback
        local error_code = data:match("error=([^&%s]+)")
        if error_code then
          local error_desc = data:match("error_description=([^&%s]+)") or "Unknown error"
          vim.schedule(function()
            vim.notify("OAuth error: " .. error_code .. " - " .. error_desc:gsub("+", " "), vim.log.levels.ERROR)
          end)
          client:write("HTTP/1.1 400 Bad Request\r\nContent-Length: 20\r\n\r\nAuthentication failed!")
          client:close()
          server:close()
          return
        end

        local code = data:match("code=([^&%s]+)")
        local returned_state = data:match("state=([^&%s]+)")

        if code then
          -- Verify state to prevent CSRF
          if returned_state ~= auth_state then
            vim.schedule(function()
              vim.notify("OAuth state mismatch! Possible CSRF attack.", vim.log.levels.ERROR)
            end)
            client:write("HTTP/1.1 403 Forbidden\r\nContent-Length: 20\r\n\r\nState mismatch!")
            client:close()
            server:close()
            return
          end

          client:write("HTTP/1.1 200 OK\r\nContent-Length: 32\r\n\r\nAuthentication successful! Close this tab.")
          client:close()
          server:close()
          -- Defer HTTP call to main loop to avoid fast event context error
          vim.schedule(function()
            M.exchange_code_for_token(code)
          end)
        end
      end
    end)
  end)

  local auth_url = string.format(
    "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=%s&state=%s",
    WHOOP_AUTH_URL,
    config.client_id,
    REDIRECT_URI,
    "read:recovery read:sleep read:workout read:cycles read:profile offline",
    auth_state
  )

  vim.fn.system({ "open", auth_url })
  vim.notify("Opening browser for Whoop authentication...", vim.log.levels.INFO)
end

function M.exchange_code_for_token(code)
  local config = get_config()

  local body = string.format(
    "grant_type=authorization_code&code=%s&redirect_uri=%s&client_id=%s&client_secret=%s",
    code,
    REDIRECT_URI,
    config.client_id,
    config.client_secret
  )

  local response = http.post(WHOOP_TOKEN_URL, body, {
    ["Content-Type"] = "application/x-www-form-urlencoded",
  })

  if response and response.access_token then
    storage.save_tokens({
      access_token = response.access_token,
      refresh_token = response.refresh_token,
      expires_at = os.time() + response.expires_in,
    })
    vim.notify("Whoop authentication successful!", vim.log.levels.INFO)
  else
    vim.notify("Failed to exchange code for token: " .. vim.inspect(response), vim.log.levels.ERROR)
  end
end

function M.refresh_access_token()
  local config = get_config()
  local tokens = storage.load_tokens()

  if not tokens or not tokens.refresh_token then
    vim.notify("No refresh token available. Please re-authenticate.", vim.log.levels.ERROR)
    M.authenticate()
    return false
  end

  local body = string.format(
    "grant_type=refresh_token&refresh_token=%s&client_id=%s&client_secret=%s",
    tokens.refresh_token,
    config.client_id,
    config.client_secret
  )

  local response = http.post(WHOOP_TOKEN_URL, body, {
    ["Content-Type"] = "application/x-www-form-urlencoded",
  })

  if response and response.access_token then
    storage.save_tokens({
      access_token = response.access_token,
      refresh_token = response.refresh_token or tokens.refresh_token,
      expires_at = os.time() + response.expires_in,
    })
    return true
  else
    vim.notify("Failed to refresh token. Please re-authenticate.", vim.log.levels.ERROR)
    M.authenticate()
    return false
  end
end

function M.get_access_token()
  local tokens = storage.load_tokens()
  if not tokens then
    return nil
  end

  if os.time() >= tokens.expires_at - 60 then
    if M.refresh_access_token() then
      tokens = storage.load_tokens()
    else
      return nil
    end
  end

  return tokens.access_token
end

return M
