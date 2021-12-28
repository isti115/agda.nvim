local state     = require('agda.state')
local utilities = require('agda.utilities')

local function buf_option (option, value)
  vim.api.nvim_buf_set_option(state.output_buf, option, value)
end

local function initialize ()
  state.output_buf = utilities.find_or_create_buf('Agda')
  state.output_win = utilities.find_or_create_win(state.output_buf)
  vim.api.nvim_win_set_option(state.output_win, 'number', false)
  buf_option('buftype', 'nofile')
end

local function set_lines (from, to, lines)
  vim.api.nvim_buf_set_lines(state.output_buf, from, to, false, lines)
end

local function clear  () set_lines(0, -1, {})            end
local function lock   () buf_option('modifiable', false) end
local function unlock () buf_option('modifiable', true)  end

local function buf_print (text)
  local lines = {}
  for line in string.gmatch(text, '[^\r\n]+') do
    table.insert(lines, line)
  end

  local last_line = vim.api.nvim_buf_line_count(state.output_buf) - 1
  set_lines(last_line, last_line, lines)
  return #lines
end

local function print_goals (goals)
  for _, g in ipairs(goals) do
    -- set_lines(g.id, g.id, { '?' .. g.id .. ' : ' .. g.type })
    buf_print('?' .. g.id .. ' : ' .. utilities.remove_qualifications(g.type))
  end
end

local function print_context (context)
  for _, c in ipairs(context) do
    buf_print(
      c.reifiedName .. ' : ' .. utilities.remove_qualifications(c.binding)
    )
  end
end

local function set_height (height)
  vim.api.nvim_win_set_height(state.output_win, height)
end

local function fit_height ()
  set_height(vim.api.nvim_buf_line_count(state.output_buf) - 1)
end

local function reset_cursor ()
  vim.api.nvim_win_set_cursor(state.output_win, { 1, 1 })
end

return {
  initialize    = initialize,
  buf_option    = buf_option,
  set_lines     = set_lines,
  clear         = clear,
  lock          = lock,
  unlock        = unlock,
  buf_print     = buf_print,
  print_goals   = print_goals,
  print_context = print_context,
  set_height    = set_height,
  fit_height    = fit_height,
  reset_cursor  = reset_cursor,
}
