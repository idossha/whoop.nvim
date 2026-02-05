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
    vim.notify("API error: " .. tostring(response.error), vim.log.levels.ERROR)
    return nil
  end

  return response
end

function M.get_profile()
  return M.make_api_request("/v1/user/profile/basic", "GET")
end

function M.get_recovery(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", start_date, end_date)
  end
  return M.make_api_request("/v1/recovery" .. params, "GET")
end

function M.get_sleep(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", start_date, end_date)
  end
  return M.make_api_request("/v1/activity/sleep" .. params, "GET")
end

function M.get_workouts(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", start_date, end_date)
  end
  return M.make_api_request("/v1/activity/workout" .. params, "GET")
end

function M.get_cycles(start_date, end_date)
  local params = ""
  if start_date and end_date then
    params = string.format("?start=%s&end=%s", start_date, end_date)
  end
  return M.make_api_request("/v1/cycle" .. params, "GET")
end

function M.refresh_all_data()
  vim.notify("Refreshing Whoop data...", vim.log.levels.INFO)

  local config = require("whoop.config").config
  local days_back = config.default_days or 7

  local end_date = os.date("%Y-%m-%d")
  local start_date = os.date("%Y-%m-%d", os.time() - days_back * 24 * 60 * 60)

  local data = {
    profile = M.get_profile(),
    recovery = M.get_recovery(start_date, end_date),
    sleep = M.get_sleep(start_date, end_date),
    workouts = M.get_workouts(start_date, end_date),
    cycles = M.get_cycles(start_date, end_date),
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

return M
