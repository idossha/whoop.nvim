local M = {}

local api = require("whoop.api")
local config = require("whoop.config").config
local storage = require("whoop.storage")
local Popup = require("nui.popup")
local Line = require("nui.line")
local Text = require("nui.text")

local dashboard_popup = nil

local function create_bar_chart(value, max, width)
  local filled = math.floor((value / max) * width)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

local function format_duration(minutes)
  local hours = math.floor(minutes / 60)
  local mins = minutes % 60
  return string.format("%dh %dm", hours, mins)
end

local function render_dashboard(data)
  local lines = {}

  table.insert(lines, "")
  table.insert(lines, "  ╔══════════════════════════════════════════════════════════════╗")
  table.insert(lines, "  ║                    🏋️  WHOOP DASHBOARD                       ║")
  table.insert(lines, "  ╚══════════════════════════════════════════════════════════════╝")
  table.insert(lines, "")

  if data.profile then
    table.insert(lines, string.format("  👤 User: %s %s", 
      data.profile.first_name or "N/A", 
      data.profile.last_name or ""))
    table.insert(lines, "")
  end

  if data.recovery and data.recovery.records then
    local recovery = data.recovery.records[1]
    if recovery and recovery.score then
      local score = recovery.score.recovery_score or 0
      local color = score >= 67 and "🟢" or (score >= 33 and "🟡" or "🔴")
      table.insert(lines, "  📊 RECOVERY")
      table.insert(lines, string.format("     Score: %s %d%% %s", color, score, create_bar_chart(score, 100, 20)))
      table.insert(lines, string.format("     RHR: %d bpm", recovery.score.resting_heart_rate or 0))
      table.insert(lines, string.format("     HRV: %d ms", recovery.score.hrv_rmssd_milli or 0))
      table.insert(lines, "")
    end
  end

  if data.sleep and data.sleep.records then
    local sleep = data.sleep.records[1]
    if sleep and sleep.score and sleep.score.stage_summary then
      table.insert(lines, "  😴 SLEEP")
      local total_milli = sleep.score.stage_summary.total_in_bed_time_milli or 0
      table.insert(lines, string.format("     Total: %s", format_duration(total_milli / 60000)))
      table.insert(lines, string.format("     Efficiency: %d%%", sleep.score.sleep_efficiency_percentage or 0))
      table.insert(lines, "")
    end
  end

  if data.workouts and data.workouts.records then
    table.insert(lines, "  💪 RECENT WORKOUTS")
    for i, workout in ipairs(data.workouts.records) do
      if i > 3 then break end
      local strain = workout.score and workout.score.strain or 0
      table.insert(lines, string.format("     %s: %s (%.1f strain)", 
        workout.start or "N/A",
        workout.sport_name or "Unknown",
        strain))
    end
    table.insert(lines, "")
  end

  if data.refreshed_at then
    local time_str = os.date("%Y-%m-%d %H:%M", data.refreshed_at)
    table.insert(lines, string.format("  Last updated: %s", time_str))
  end

  table.insert(lines, "")
  table.insert(lines, "  Press 'r' to refresh | 'q' to quit")

  return lines
end

function M.open()
  if dashboard_popup then
    dashboard_popup:unmount()
    dashboard_popup = nil
  end

  local data = api.get_cached_or_refresh()
  
  if not data then
    vim.notify("No data available. Run :WhoopAuth to authenticate.", vim.log.levels.ERROR)
    return
  end

  dashboard_popup = Popup({
    position = "50%",
    size = {
      width = 80,
      height = 30,
    },
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Whoop Dashboard ",
        top_align = "center",
      },
    },
    win_options = {
      wrap = false,
      cursorline = false,
    },
  })

  dashboard_popup:mount()

  local lines = render_dashboard(data)
  vim.api.nvim_buf_set_lines(dashboard_popup.bufnr, 0, -1, false, lines)

  vim.api.nvim_buf_set_keymap(dashboard_popup.bufnr, "n", "q", "<cmd>lua require('whoop.ui.dashboard').close()<cr>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(dashboard_popup.bufnr, "n", "r", "<cmd>lua require('whoop.ui.dashboard').refresh()<cr>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(dashboard_popup.bufnr, "n", "<esc>", "<cmd>lua require('whoop.ui.dashboard').close()<cr>", { noremap = true, silent = true })

  vim.api.nvim_win_set_option(dashboard_popup.winid, "cursorline", false)
  vim.api.nvim_win_set_cursor(dashboard_popup.winid, { 1, 0 })
end

function M.close()
  if dashboard_popup then
    dashboard_popup:unmount()
    dashboard_popup = nil
  end
end

function M.refresh()
  if dashboard_popup then
    dashboard_popup:unmount()
    dashboard_popup = nil
  end
  api.refresh_all_data()
  M.open()
end

return M
