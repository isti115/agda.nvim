--[[
  Agda interaction plugin for NeoVim written in Lua
  István Donkó (Isti115@GitHub)
  Copyright (C) 2021
--]]

local Job = require('plenary.job')
local command = require('agda.command')

-- print('agda-mode loaded')

local code_buf = 0
local buf = vim.api.nvim_create_buf(false, true)
-- vim.api.nvim_buf_set_name(buf, 'Agda')
local win
-- Highlighting Namespace
local hlns = vim.api.nvim_create_namespace('Agda')

local function current_file ()
  -- vim.fn.expand('%')
  return vim.api.nvim_buf_get_name(code_buf)
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
    -- vim.api.nvim_win_set_cursor(win, { 1, 1 })
  end
end

local job = Job:new {
  command = 'agda',
  args = {'--interaction-json'},
  on_stdout = vim.schedule_wrap(function (_, data)
    unlock()
    local message = vim.fn.json_decode(string.sub(data, 1, 5) == 'JSON>' and string.sub(data, 6) or data)

    -- print(vim.inspect(message))
    if message.kind == 'DisplayInfo' then
      if message.info.kind == 'AllGoalsWarnings' then
        clear()
        goals = {}

        -- vim.api.nvim_win_set_height(win, table.getn(message.info.visibleGoals))
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
        -- vim.api.nvim_win_set_height(win, 2)

      elseif message.info.kind == 'Error' then
        print('Error: ' .. message.info.error.message)

      end

    elseif message.kind == 'MakeCase' then
      vim.api.nvim_buf_set_lines(code_buf,
        message.interactionPoint.range[1].start.line - 1,
        message.interactionPoint.range[1]['end'].line,
        false, message.clauses)

    elseif message.kind == 'HighlightingInfo' then
      for _, hl in ipairs(message.info.payload) do
        local from = byte_to_line_col(hl.range[1])
        local to = byte_to_line_col(hl.range[2])
        vim.api.nvim_buf_add_highlight(code_buf, hlns, 'agda' .. hl.atoms[1], from.line - 1, from.col, to.col)
      end

    elseif message.kind == 'ClearHighlighting' then
      vim.api.nvim_buf_clear_namespace(code_buf, hlns, 0, -1)

    elseif message.kind == 'RunningInfo' then
      print(message.message)

    -- else
    --   print(vim.inspect(message))

    end

    lock()
  end)
}

local function send (message) job:send(message .. '\n') end

local function window ()
  vim.cmd('split')
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  vim.api.nvim_win_set_option(win, 'number', false)
end

local function start ()
  job:start()
end

local function load ()
  if not job.stdin then start() end
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