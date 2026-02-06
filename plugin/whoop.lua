-- whoop.nvim
-- WHOOP fitness integration for Neovim
-- https://github.com/idossha/whoop.nvim

if vim.fn.has("nvim-0.8") == 0 then
  vim.notify("whoop.nvim requires Neovim 0.8 or higher", vim.log.levels.ERROR)
  return
end
