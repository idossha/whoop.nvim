local M = {}

local api = require("whoop.api")
local storage = require("whoop.storage")
local Popup = require("nui.popup")

local dashboard_popup = nil
local WIDTH = 100

-- Box drawing characters
local box = {
  tl = "┌", tr = "┐", bl = "└", br = "┘",
  h = "─", v = "│", t = "┬", b = "┴", l = "├", r = "┤", c = "┼"
}

-- Calculate display width using vim's built-in function
local function str_width(str)
  return vim.fn.strdisplaywidth(str)
end

local function format_duration(minutes)
  local hours = math.floor(minutes / 60)
  local mins = math.floor(minutes % 60)
  return string.format("%dh%02d", hours, mins)
end

local function format_duration_short(minutes)
  local hours = math.floor(minutes / 60)
  local mins = math.floor(minutes % 60)
  return string.format("%d:%02d", hours, mins)
end

local function pad(str, width, align)
  align = align or "left"
  local len = str_width(str)
  if len >= width then
    return str:sub(1, width)
  end
  local padding = width - len
  if align == "center" then
    local left = math.floor(padding / 2)
    local right = padding - left
    return string.rep(" ", left) .. str .. string.rep(" ", right)
  elseif align == "right" then
    return string.rep(" ", padding) .. str
  else
    return str .. string.rep(" ", padding)
  end
end

local function horizontal_bar(value, max, width)
  local ratio = math.min(value / max, 1)
  local filled = math.floor(ratio * width)
  return string.rep("█", filled) .. string.rep("░", width - filled)
end

-- Parse ISO 8601 date safely
local function parse_iso_date(iso_string)
  if not iso_string or iso_string == "" then
    return nil, nil
  end
  
  -- Pattern: 2026-02-05T14:30:00.000Z or 2026-02-05T14:30:00Z
  local year, month, day = iso_string:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
  local hour, min = iso_string:match("T(%d%d):(%d%d)")
  
  if year and month and day then
    return string.format("%s/%s", month, day), hour and min and string.format("%s:%s", hour, min) or nil
  end
  
  return nil, nil
end

local function get_sleep_data_for_week(data)
  if not data.sleep or not data.sleep.records then
    return nil
  end
  
  local days = {}
  for i = 1, math.min(7, #data.sleep.records) do
    local sleep = data.sleep.records[i]
    if sleep and sleep.score then
      local date_str, _ = parse_iso_date(sleep.start)
      
      table.insert(days, {
        date = date_str or "--/--",
        hours = (sleep.score.stage_summary and sleep.score.stage_summary.total_in_bed_time_milli or 0) / 3600000,
        efficiency = sleep.score.sleep_efficiency_percentage or 0,
      })
    end
  end
  return days
end

local function render_dashboard(data)
  local lines = {}
  local w = WIDTH
  
  -- Helper to create a line of exactly width w
  local function make_line(content)
    local line_width = str_width(content)
    if line_width < w - 2 then
      return box.v .. content .. string.rep(" ", w - 2 - line_width) .. box.v
    elseif line_width > w - 2 then
      return box.v .. content:sub(1, w - 2) .. box.v
    else
      return box.v .. content .. box.v
    end
  end
  
  -- ========== HEADER ==========
  table.insert(lines, box.tl .. string.rep(box.h, w - 2) .. box.tr)
  table.insert(lines, make_line(pad(" WHOOP DASHBOARD ", w - 2, "center")))
  table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
  
  -- ========== USER INFO ==========
  if data.profile then
    local user_str = string.format("  %s %s  |  ID: %d", 
      data.profile.first_name or "User",
      data.profile.last_name or "",
      data.profile.user_id or 0)
    table.insert(lines, make_line(pad(user_str, w - 2)))
    table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
  end
  
  -- ========== TODAY'S METRICS ==========
  local recovery_data = data.recovery and data.recovery.records and data.recovery.records[1]
  local sleep_data = data.sleep and data.sleep.records and data.sleep.records[1]
  
  -- Recovery
  if recovery_data and recovery_data.score then
    local score = recovery_data.score.recovery_score or 0
    local rhr = recovery_data.score.resting_heart_rate or 0
    local hrv = recovery_data.score.hrv_rmssd_milli or 0
    
    table.insert(lines, make_line("  RECOVERY" .. string.rep(" ", w - 12)))
    local bar = horizontal_bar(score, 100, 32)
    table.insert(lines, make_line(string.format("    Score: %3d%% %s", score, bar)))
    table.insert(lines, make_line(string.format("    RHR: %d bpm    HRV: %.1f ms", rhr, hrv)))
  end
  
  -- Separator if both exist
  if recovery_data and sleep_data then
    table.insert(lines, make_line(""))
  end
  
  -- Sleep
  if sleep_data and sleep_data.score and sleep_data.score.stage_summary then
    local stages = sleep_data.score.stage_summary
    local total_min = (stages.total_in_bed_time_milli or 0) / 60000
    local awake_min = (stages.total_awake_time_milli or 0) / 60000
    local light_min = (stages.total_light_sleep_time_milli or 0) / 60000
    local deep_min = (stages.total_slow_wave_sleep_time_milli or 0) / 60000
    local rem_min = (stages.total_rem_sleep_time_milli or 0) / 60000
    local efficiency = sleep_data.score.sleep_efficiency_percentage or 0
    
    table.insert(lines, make_line("  LAST NIGHT'S SLEEP" .. string.rep(" ", w - 21)))
    table.insert(lines, make_line(string.format("    Total: %s  |  Efficiency: %d%%", format_duration(total_min), efficiency)))
    
    -- Sleep stages summary
    local total_all = awake_min + light_min + deep_min + rem_min
    if total_all > 0 then
      local awake_pct = math.floor((awake_min / total_all) * 100)
      local light_pct = math.floor((light_min / total_all) * 100)
      local deep_pct = math.floor((deep_min / total_all) * 100)
      local rem_pct = math.floor((rem_min / total_all) * 100)
      
      local stages_str = string.format("    Awake: %s (%d%%)  Light: %s (%d%%)  Deep: %s (%d%%)  REM: %s (%d%%)",
        format_duration_short(awake_min), awake_pct,
        format_duration_short(light_min), light_pct,
        format_duration_short(deep_min), deep_pct,
        format_duration_short(rem_min), rem_pct)
      table.insert(lines, make_line(stages_str))
    end
  end
  
  table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
  
  -- ========== SLEEP HISTORY ==========
  local week_sleep = get_sleep_data_for_week(data)
  if week_sleep and #week_sleep > 0 then
    table.insert(lines, make_line(pad(" SLEEP HISTORY (7 DAYS) ", w - 2, "center")))
    table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
    
    local col_width = math.floor((w - 4) / #week_sleep)
    local remaining = (w - 4) - (col_width * #week_sleep)
    
    -- Date row
    local date_row = ""
    for i, day in ipairs(week_sleep) do
      date_row = date_row .. pad(day.date, col_width, "center")
    end
    date_row = date_row .. string.rep(" ", remaining)
    table.insert(lines, make_line(" " .. date_row))
    
    -- Graph rows - vertical bars
    local max_hours = 10
    for row = max_hours, 1, -1 do
      local graph_row = ""
      for _, day in ipairs(week_sleep) do
        local char = (day.hours >= row) and "█" or "░"
        graph_row = graph_row .. pad(char, col_width, "center")
      end
      graph_row = graph_row .. string.rep(" ", remaining)
      table.insert(lines, make_line(" " .. graph_row))
    end
    
    -- Hours row
    local hours_row = ""
    for _, day in ipairs(week_sleep) do
      hours_row = hours_row .. pad(string.format("%.1fh", day.hours), col_width, "center")
    end
    hours_row = hours_row .. string.rep(" ", remaining)
    table.insert(lines, make_line(" " .. hours_row))
    
    -- Efficiency row
    local eff_row = ""
    for _, day in ipairs(week_sleep) do
      eff_row = eff_row .. pad(string.format("%d%%", day.efficiency), col_width, "center")
    end
    eff_row = eff_row .. string.rep(" ", remaining)
    table.insert(lines, make_line(" " .. eff_row))
    
    table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
  end
  
  -- ========== RECENT WORKOUTS ==========
  if data.workouts and data.workouts.records and #data.workouts.records > 0 then
    table.insert(lines, make_line(pad(" RECENT WORKOUTS ", w - 2, "center")))
    table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
    
    -- Define column widths for even spacing
    local col_date = 10     -- MM/DD
    local col_activity = 16 -- Activity name
    local col_strain = 18   -- Bar + value
    local col_dur = 10      -- Duration
    local col_hr = 8        -- Heart rate
    local spacer = 2        -- Space between columns
    
    -- Header row
    local header = "  " .. 
      pad("DATE", col_date) .. string.rep(" ", spacer) ..
      pad("ACTIVITY", col_activity) .. string.rep(" ", spacer) ..
      pad("STRAIN", col_strain) .. string.rep(" ", spacer) ..
      pad("DURATION", col_dur) .. string.rep(" ", spacer) ..
      pad("HR", col_hr)
    table.insert(lines, make_line(header))
    table.insert(lines, box.v .. string.rep(box.h, w - 2) .. box.v)
    
    for i, workout in ipairs(data.workouts.records) do
      if i > 5 then break end
      
      -- Parse date from ISO string
      local date_str = "--/--"
      if workout.start then
        local month, day = workout.start:match("%-(%d%d)%-(%d%d)T")
        if month and day then
          date_str = month .. "/" .. day
        end
      end
      
      local activity = workout.sport_name or "Unknown"
      activity = activity:sub(1, 1):upper() .. activity:sub(2, col_activity)
      
      local strain = workout.score and workout.score.strain or 0
      local strain_bar = horizontal_bar(strain, 21, 10)
      local strain_str = strain_bar .. " " .. string.format("%.1f", strain)
      
      -- Calculate duration using start and end fields (API v2)
      local duration = 0
      if workout.start and workout["end"] then
        -- Parse ISO 8601 timestamps
        local start_year, start_month, start_day, start_hour, start_min = workout.start:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
        local end_year, end_month, end_day, end_hour, end_min = workout["end"]:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
        
        if start_year and end_year then
          -- Convert to timestamps
          local start_time = os.time({
            year = tonumber(start_year),
            month = tonumber(start_month),
            day = tonumber(start_day),
            hour = tonumber(start_hour),
            min = tonumber(start_min)
          })
          local end_time = os.time({
            year = tonumber(end_year),
            month = tonumber(end_month),
            day = tonumber(end_day),
            hour = tonumber(end_hour),
            min = tonumber(end_min)
          })
          
          if start_time and end_time then
            duration = (end_time - start_time) / 60 -- in minutes
          end
        end
      end
      
      local avg_hr = workout.score and workout.score.average_heart_rate or 0
      
      local line = "  " ..
        pad(date_str, col_date) .. string.rep(" ", spacer) ..
        pad(activity, col_activity) .. string.rep(" ", spacer) ..
        pad(strain_str, col_strain) .. string.rep(" ", spacer) ..
        pad(format_duration(duration), col_dur) .. string.rep(" ", spacer) ..
        pad(tostring(avg_hr) .. " bpm", col_hr)
      
      table.insert(lines, make_line(line))
    end
    
    table.insert(lines, box.l .. string.rep(box.h, w - 2) .. box.r)
  end
  
  -- ========== FOOTER ==========
  table.insert(lines, box.bl .. string.rep(box.h, w - 2) .. box.br)
  
  if data.refreshed_at then
    local footer = string.format(" Last updated: %s  |  [r] Refresh  |  [q] Quit", os.date("%Y-%m-%d %H:%M", data.refreshed_at))
    table.insert(lines, pad(footer, w))
  end
  
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
      width = WIDTH + 2,
      height = 42,
    },
    enter = true,
    focusable = true,
    border = {
      style = "none",
    },
    win_options = {
      wrap = false,
      cursorline = false,
      number = false,
      relativenumber = false,
    },
  })

  dashboard_popup:mount()

  local lines = render_dashboard(data)
  vim.api.nvim_buf_set_lines(dashboard_popup.bufnr, 0, -1, false, lines)

  -- Syntax highlighting
  vim.api.nvim_buf_call(dashboard_popup.bufnr, function()
    vim.cmd([[
      syntax clear
      syn match WhoopBorder "[┌┐└┘├┤┬┴┼│─]"
      syn match WhoopHeader "WHOOP DASHBOARD"
      syn match WhoopSection " SLEEP HISTORY\| RECENT WORKOUTS"
      syn match WhoopLabel "RECOVERY\|LAST NIGHT'S SLEEP"
      syn match WhoopDate "\d\d/\d\d"
      
      hi WhoopBorder ctermfg=240 guifg=#586e75
      hi WhoopHeader ctermfg=81 guifg=#5fd7ff cterm=bold gui=bold
      hi WhoopSection ctermfg=178 guifg=#d7af00 cterm=bold gui=bold
      hi WhoopLabel ctermfg=250 guifg=#bcbcbc
      hi WhoopDate ctermfg=245 guifg=#8a8a8a
    ]])
  end)

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
