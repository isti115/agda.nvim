local utilities = require('agda.utilities')

local buf = utilities.find_or_create_buf('Agda')
local win

local function buf_option (option, value)
  vim.api.nvim_buf_set_option(buf, option, value)
end

buf_option('buftype', 'nofile')

local function set_lines (from, to, lines)
  vim.api.nvim_buf_set_lines(buf, from, to, false, lines)
end

local function clear  () set_lines(0, -1, {})            end
local function lock   () buf_option('modifiable', false) end
local function unlock () buf_option('modifiable', true)  end

local function buf_print (text)
  local lines = {}
  for line in string.gmatch(text, '[^\r\n]+') do
    table.insert(lines, line)
  end

  local last_line = vim.api.nvim_buf_line_count(buf) - 1
  set_lines(last_line, last_line, lines)
end

local function print_goals (goals)
  for _, g in ipairs(goals) do
    set_lines(g.id, g.id, { '?' .. g.id .. ' : ' .. g.type })
    vim.api.nvim_win_set_cursor(win, { 1, 1 })
  end
end

local function open_window ()
  local code_win = vim.api.nvim_get_current_win()
  win = utilities.find_or_create_win(buf)
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_set_current_win(code_win)
end

local function set_height (height)
  vim.api.nvim_win_set_height(win, height)
end

return {
  buf         = buf,
  win         = win,
  buf_option  = buf_option,
  set_lines   = set_lines,
  clear       = clear,
  lock        = lock,
  unlock      = unlock,
  buf_print   = buf_print,
  print_goals = print_goals,
  open_window = open_window,
  set_height  = set_height,
}
