local M = {}

local data_dir = vim.fn.stdpath("data") .. "/whoop"
local token_file = data_dir .. "/tokens.json"
local cache_file = data_dir .. "/cache.json"

function M.ensure_data_dir()
  vim.fn.mkdir(data_dir, "p")
end

function M.save_tokens(tokens)
  M.ensure_data_dir()
  local file = io.open(token_file, "w")
  if file then
    file:write(vim.json.encode(tokens))
    file:close()
  end
end

function M.load_tokens()
  local file = io.open(token_file, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()

  local ok, tokens = pcall(vim.json.decode, content)
  if ok then
    return tokens
  end
  return nil
end

function M.save_cache(data)
  M.ensure_data_dir()
  local file = io.open(cache_file, "w")
  if file then
    data.cached_at = os.time()
    file:write(vim.json.encode(data))
    file:close()
  end
end

function M.load_cache()
  local file = io.open(cache_file, "r")
  if not file then
    return nil
  end
  local content = file:read("*all")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if ok then
    return data
  end
  return nil
end

function M.clear_cache()
  vim.fn.delete(cache_file)
end

function M.clear_tokens()
  vim.fn.delete(token_file)
end

return M
