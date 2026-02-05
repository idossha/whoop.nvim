local M = {}

function M.get(url, headers)
  local curl = require("plenary.curl")

  local opts = {
    url = url,
    headers = headers or {},
  }

  local response = curl.get(opts)

  if response.status ~= 200 then
    return { error = "HTTP " .. response.status, body = response.body }
  end

  local ok, data = pcall(vim.json.decode, response.body)
  if ok then
    return data
  else
    return { error = "Failed to parse JSON", body = response.body }
  end
end

function M.post(url, body, headers)
  local curl = require("plenary.curl")

  local opts = {
    url = url,
    body = body,
    headers = headers or {},
  }

  local response = curl.post(opts)

  if response.status < 200 or response.status >= 300 then
    return { error = "HTTP " .. response.status, body = response.body }
  end

  local ok, data = pcall(vim.json.decode, response.body)
  if ok then
    return data
  else
    return { error = "Failed to parse JSON", body = response.body }
  end
end

return M
