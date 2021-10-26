--[[
  Agda interaction plugin for NeoVim written in Lua
  István Donkó (Isti115@GitHub)
  Copyright (C) 2021
--]]

local Job = require('plenary.job')
local command = require('agda.command')

-- print('agda-mode loaded')

local job
local code_buf = 0

local function find_or_create_buf (name)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    -- if vim.api.nvim_buf_get_name(b) == name then -- returns the whole path
    if vim.fn.bufname(b) == name then
      return b
    end
  end

  local new = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(new, name)
  return new
end

local function find_or_create_win (buf)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then
      return w
    end
  end

  vim.cmd('1new') -- open a new window below the current one with minimal height
  local new = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(new, buf)

  return new
end

local buf = find_or_create_buf('Agda')
local win
-- Highlighting Namespace
local hlns = vim.api.nvim_create_namespace('Agda')

local function current_file ()
  -- vim.fn.expand('%')
  return vim.api.nvim_buf_get_name(code_buf)
end

local function character_to_byte_map (content)
  local position_map = {}
  for i = 1, #content do
    local b = string.byte(content, i)
    -- skip unicode continuation characters
    -- (https://en.wikipedia.org/wiki/UTF-8#Encoding)
    if not (0x80 <= b and b < 0xc0) then
      table.insert(position_map, i)
    end
  end
  -- add position index after last character for exclusive ranges
  table.insert(position_map, #content + 1)
  return position_map
end

local function byte_to_line_col (byte)
  local line = vim.fn.byte2line(byte)
  local col = byte - vim.fn.line2byte(line)
  return {
    line = line,
    col  = col,
  }
end

local function buf_option (option, value)
  vim.api.nvim_buf_set_option(buf, option, value)
end

buf_option('buftype', 'nofile')

local function set_lines (from, to, lines)
  vim.api.nvim_buf_set_lines(buf, from, to, false, lines)
end

local function clear  () set_lines(code_buf, -1, {})     end
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

local goals = {}

local function print_goals ()
  for _, g in ipairs(goals) do
    set_lines(g.id, g.id, { '?' .. g.id .. ' : ' .. g.type })
    vim.api.nvim_win_set_cursor(win, { 1, 1 })
  end
end

local function send (message) job:send(message .. '\n') end

local function window ()
  local code = vim.api.nvim_get_current_win()
  win = find_or_create_win(buf)
  vim.api.nvim_set_current_win(code)
end

local function start ()
  job:start()
end

local function load ()
  vim.api.nvim_command('silent write')
  if not job.stdin then start() end
  window()
  send(command.make(
    current_file(),
    command.load(current_file())
  ))
end

local function version ()
  send(command.make(
    current_file(),
    command.version()
  ))
end

local function stop ()
  job:shutdown()
end

local function test ()
  print('pid: ', job.pid)
end

local function goal_for_position (line, col)
  for _, g in pairs(goals) do
    -- `end` is a reserved keyword in lua...
    if  g.range.start.line <= line and line <= g.range['end'].line
    and g.range.start.col  <= col  and col  <= g.range['end'].col
    then
       return g.id
    end
  end
end

local function goal_for_cursor ()
  local position = vim.api.nvim_win_get_cursor(code_buf)
  local line, col = position[1], position[2] + 1
  col = vim.fn.virtcol('.') -- Multi-byte workaround
  -- col = vim.api.nvim_eval('virtcol(".")') -- Multi-byte workaround
  -- https://www.reddit.com/r/agda/comments/qamibt/comment/hhjkp99
  return goal_for_position(line, col)
end

local function case ()
  local goal = goal_for_cursor()
  if not goal then
    print 'Place the cursor in a goal to case split!'
    return
  end

  local expression = vim.fn.input('case: ')

  send(command.make(
    current_file(),
    command.case(goal, expression)
  ))
end

local function context ()
  local goal = goal_for_cursor()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  send(command.make(
    current_file(),
    command.context(goal)
  ))
end

local function receive (_, data)
  unlock()
  local message = vim.fn.json_decode(string.sub(data, 1, 5) == 'JSON>' and string.sub(data, 6) or data)

  -- print(vim.inspect(message))
  if message.kind == 'DisplayInfo' then
    if message.info.kind == 'AllGoalsWarnings' then
      clear()
      goals = {}

      vim.api.nvim_win_set_height(win, #message.info.visibleGoals)
      for _, g in ipairs(message.info.visibleGoals) do
        table.insert(goals, {
          id = g.constraintObj.id,
          type = g.type,
          range = g.constraintObj.range[1],
        })
      end

      print_goals()

    elseif message.info.kind == 'Context' then
      -- print(vim.inspect(message))
      clear()
      for _, c in ipairs(message.info.context) do
        -- set_lines(i - 1, i - 1, { c.reifiedName .. ' : ' .. c.binding })
        buf_print(c.reifiedName .. ' : ' .. c.binding)
      end

    elseif message.info.kind == 'Version' then
      set_lines(code_buf, -1, { 'Agda version:', message.info.version })
      vim.api.nvim_win_set_height(win, 2)

    elseif message.info.kind == 'Error' then
      print('Error: ' .. message.info.error.message)

    end

  elseif message.kind == 'MakeCase' then
    vim.api.nvim_buf_set_lines(code_buf,
      message.interactionPoint.range[1].start.line - 1,
      message.interactionPoint.range[1]['end'].line,
      false, message.clauses)

    load()

  elseif message.kind == 'HighlightingInfo' then
    local position_map = character_to_byte_map(
      table.concat(vim.api.nvim_buf_get_lines(code_buf, 0, -1, false), '\n')
    )

    for _, hl in ipairs(message.info.payload) do
      local from = byte_to_line_col(position_map[hl.range[1]])
      local to = byte_to_line_col(position_map[hl.range[2]])
      vim.api.nvim_buf_add_highlight(
        code_buf, hlns, 'agda' .. hl.atoms[1], from.line - 1, from.col, to.col
      )
    end

  elseif message.kind == 'ClearHighlighting' then
    vim.api.nvim_buf_clear_namespace(code_buf, hlns, 0, -1)

  elseif message.kind == 'RunningInfo' then
    print(message.message)

  -- else
  --   print(vim.inspect(message))

  end

  lock()
end

job = Job:new {
  command = 'agda',
  args = {'--interaction-json'},
  on_stdout = vim.schedule_wrap(receive)
}

return {
  case    = case,
  context = context,
  load    = load,
  start   = start,
  stop    = stop,
  test    = test,
  version = version,
  window  = window,
}
