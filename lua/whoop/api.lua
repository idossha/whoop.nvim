local M = {}

local auth = require("whoop.auth")
local storage = require("whoop.storage")
local http = require("whoop.http")

local API_BASE = "https://api.prod.whoop.com/developer"

function M.make_api_request(endpoint, method, body)
  local token = auth.get_access_token()
  if not token then
    vim.notify("Not authenticated. Run :WhoopAuth", vim.log.levels.ERROR)
    return nil
  end

  local url = API_BASE .. endpoint
  
  -- Debug logging
  vim.notify("WHOOP API Request: " .. url, vim.log.levels.DEBUG)
  
  local headers = {
    ["Authorization"] = "Bearer " .. token,
    ["Content-Type"] = "application/json",
  }

  local response
  if method == "GET" then
    response = http.get(url, headers)
  elseif method == "POST" then
    response = http.post(url, vim.json.encode(body), headers)
  end

  if response and response.error then
    vim.notify("API error: " .. tostring(response.error) .. " for URL: " .. url, vim.log.levels.ERROR)
    if response.body then
      vim.notify("Response body: " .. tostring(response.body), vim.log.levels.DEBUG)
    end
    return nil
  end

  return response
end

function M.get_profile()
  return M.make_api_request("/v2/user/profile/basic", "GET")
end

local function url_encode(str)
  if str then
    str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
    str = string.gsub(str, " ", "+")
  end
  return str
end

function M.get_recovery(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", url_encode(start_date), url_encode(end_date))
  end
  return M.make_api_request("/v2/recovery" .. params, "GET")
end

function M.get_sleep(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", url_encode(start_date), url_encode(end_date))
  end
  return M.make_api_request("/v2/activity/sleep" .. params, "GET")
end

function M.get_workouts(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", url_encode(start_date), url_encode(end_date))
  end
  return M.make_api_request("/v2/activity/workout" .. params, "GET")
end

function M.get_cycles(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", url_encode(start_date), url_encode(end_date))
  end
  return M.make_api_request("/v2/cycle" .. params, "GET")
end

function M.refresh_all_data()
  vim.notify("Refreshing Whoop data...", vim.log.levels.INFO)

  local config = require("whoop.config").config
  local days_back = config.default_days or 7

  -- v2 API expects ISO 8601 datetime format
  local end_time = os.date("!%Y-%m-%dT%H:%M:%SZ")
  local start_time = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() - days_back * 24 * 60 * 60)

  vim.notify("Date range: " .. start_time .. " to " .. end_time, vim.log.levels.DEBUG)

  local data = {
    profile = M.get_profile(),
    recovery = M.get_recovery(start_time, end_time),
    sleep = M.get_sleep(start_time, end_time),
    workouts = M.get_workouts(start_time, end_time),
    cycles = M.get_cycles(start_time, end_time),
    refreshed_at = os.time(),
  }

  storage.save_cache(data)
  vim.notify("Whoop data refreshed!", vim.log.levels.INFO)

  return data
end

function M.get_cached_or_refresh()
  local config = require("whoop.config").config
  local cache = storage.load_cache()

  if cache and cache.cached_at then
    local cache_age = os.time() - cache.cached_at
    if cache_age < config.refresh_interval then
      return cache
    end
  end

  if config.auto_refresh then
    return M.refresh_all_data()
  end

  return cache
end

-- Debug function to test API connectivity
function M.test_api()
  vim.notify("Testing Whoop API v2...", vim.log.levels.INFO)
  
  -- Check if we have a token
  local token = auth.get_access_token()
  if not token then
    vim.notify("No valid access token found. Run :WhoopAuth to authenticate.", vim.log.levels.ERROR)
    return
  end
  
  vim.notify("Token found (length: " .. #token .. ")", vim.log.levels.DEBUG)
  
  -- Test profile endpoint (simplest endpoint)
  local profile = M.get_profile()
  if profile then
    vim.notify("✓ Profile endpoint working", vim.log.levels.INFO)
    vim.notify("  User: " .. (profile.first_name or "N/A") .. " " .. (profile.last_name or ""), vim.log.levels.INFO)
  else
    vim.notify("✗ Profile endpoint failed - token may be expired", vim.log.levels.ERROR)
    vim.notify("Try running :WhoopAuth to re-authenticate", vim.log.levels.INFO)
  end
  
  -- Test recovery endpoint
  local now = os.date("!%Y-%m-%dT%H:%M:%SZ")
  local yesterday = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() - 24 * 60 * 60)
  vim.notify("Testing with date range: " .. yesterday .. " to " .. now, vim.log.levels.DEBUG)
  local recovery = M.get_recovery(yesterday, now)
  if recovery then
    vim.notify("✓ Recovery endpoint working", vim.log.levels.INFO)
    if recovery.records and #recovery.records > 0 then
      vim.notify("  Found " .. #recovery.records .. " recovery records", vim.log.levels.INFO)
    else
      vim.notify("  No recovery records in date range", vim.log.levels.WARN)
    end
  else
    vim.notify("✗ Recovery endpoint failed", vim.log.levels.ERROR)
  end
end

function M.clear_auth()
  storage.clear_tokens()
  vim.notify("Authentication cleared. Run :WhoopAuth to re-authenticate.", vim.log.levels.INFO)
end

return M
