--[[
  Agda interaction plugin for NeoVim written in Lua
  István Donkó (Isti115@GitHub)
  Copyright (C) 2021

  Terminology:
    + nvim:
      - top  : row number starting from zero
      - left : byte offset from the beginning of the line
      - byte : byte offset from the beginning of the file
    + Agda:
      - line : row number starting from one
      - col  : character offset from the beginning of the line
      - pos  : character offset from the beginning of the file

  Notes:
    * Agda uses `start` and `end` for the limits of ranges,
      but `end` is a reserved keyword in Lua...
--]]

local Job = require('plenary.job')
local utilities = require('agda.utilities')
local output = require('agda.output')
local commands = require('agda.commands')

-- print('agda-mode loaded')

local job
local code_buf = 0
local code_win = 0
local pos_to_byte
local function update_pos_to_byte ()
  pos_to_byte = utilities.character_to_byte_map(
    table.concat(vim.api.nvim_buf_get_lines(code_buf, 0, -1, false), '\n')
  )
end

local function pos_to_line_left (pos)
  return utilities.byte_to_line_left(pos_to_byte[pos])
end

-- Highlighting Namespace
local hlns = vim.api.nvim_create_namespace('Agda')

local function current_file ()
  -- vim.fn.expand('%')
  return vim.api.nvim_buf_get_name(code_buf)
end

local goals = {}

local function start ()        job:start()               end
local function stop  ()        job:shutdown()            end
local function send  (message) job:send(message .. '\n') end
local function test  ()        print('pid: ', job.pid)   end

local function load ()
  code_buf = vim.api.nvim_get_current_buf()
  code_win = vim.api.nvim_get_current_win()

  vim.api.nvim_command('%s/?/{! !}/ge') -- TODO silent instead of e?
  vim.api.nvim_command('noh') -- TODO find better solution
  vim.api.nvim_command('silent write')
  if not job.stdin then start() end
  output.open_window()
  send(commands.make(
    current_file(),
    commands.load(current_file())
  ))
end

local function find_surrounding_goals ()
  local position = utilities.get_cursor_position(code_win)

  if #goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end

  local previous = goals[#goals]
  local next = goals[1]

  for _, g in ipairs(goals) do
    if utilities.is_before(g.range['end'], position) then
      previous = g
    elseif utilities.is_before(position, g.range.start) then
      next = g
      return previous, next
    end
  end

  return previous, next
end

local function goal_for_position (position)
  for _, g in pairs(goals) do
    if  utilities.is_before(g.range.start, position)
    and utilities.is_before(position, g.range['end'])
    then
       return g.id
    end
  end
end

local function goal_for_cursor ()
  local position = utilities.get_cursor_position(code_win)
  return goal_for_position(position)
end

local function back ()
  if #goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end
  local previous, _ = find_surrounding_goals()
  -- vim.api.nvim_win_set_cursor(
  --   code_win,
  --   previous.range.start.line,
  --   previous.range.start.col
  -- ) -- doesn't count multi-byte...
  vim.api.nvim_command(
    'normal ' ..
    previous.range.start.line .. 'G' ..
    previous.range.start.col + 2 .. '|'
  )
end

local function forward ()
  if #goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end
  local _, next = find_surrounding_goals()
  vim.api.nvim_command(
    'normal ' ..
    next.range.start.line .. 'G' ..
    next.range.start.col + 2 .. '|'
  )
end

local function version ()
  send(commands.make(
    current_file(),
    commands.version()
  ))
end

local function case ()
  local goal = goal_for_cursor()
  if not goal then
    print 'Place the cursor in a goal to case split!'
    return
  end

  local expression = vim.fn.input('case: ')

  send(commands.make(
    current_file(),
    commands.case(goal, expression)
  ))
end

local function auto ()
  local goal = goal_for_cursor()
  if not goal then
    print 'Place the cursor in a goal to invoke auto!'
    return
  end

  send(commands.make(
    current_file(),
    commands.auto(goal)
  ))
end

local function refine ()
  local goal = goal_for_cursor()
  if not goal then
    print 'Place the cursor in a goal to refine!'
    return
  end

  send(commands.make(
    current_file(),
    commands.refine(goal)
  ))
end

local function context ()
  local goal = goal_for_cursor()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  send(commands.make(
    current_file(),
    commands.context(goal)
  ))
end

local function window ()
  output.open_window()
end

local function receive (_, data)
  output.unlock()
  local message = vim.fn.json_decode(
    string.sub(data, 1, 5) == 'JSON>' and string.sub(data, 6) or data
  )

  -- print(vim.inspect(message))
  if message.kind == 'DisplayInfo' then
    if message.info.kind == 'AllGoalsWarnings' then
      output.clear()
      goals = {}

      output.set_height(#message.info.visibleGoals)
      for _, g in ipairs(message.info.visibleGoals) do
        table.insert(goals, {
          id = g.constraintObj.id,
          type = g.type,
          range = g.constraintObj.range[1],
        })
      end

      output.print_goals(goals)

    elseif message.info.kind == 'Context' then
      -- print(vim.inspect(message))
      output.clear()

      output.set_height(#message.info.context)
      for _, c in ipairs(message.info.context) do
        -- set_lines(i - 1, i - 1, { c.reifiedName .. ' : ' .. c.binding })
        output.buf_print(c.reifiedName .. ' : ' .. c.binding)
      end

    elseif message.info.kind == 'Version' then
      output.set_lines(0, -1, { 'Agda version:', message.info.version })
      output.set_height(2)

    elseif message.info.kind == 'Error' then
      print('Error: ' .. message.info.error.message)

    end

  elseif message.kind == 'MakeCase' then
    vim.api.nvim_buf_set_lines(code_buf,
      message.interactionPoint.range[1].start.line - 1,
      message.interactionPoint.range[1]['end'].line,
      false, message.clauses)

    load()

  elseif message.kind == 'GiveAction' then
    update_pos_to_byte()
    local range = message.interactionPoint.range[1]
    local from = pos_to_line_left(range.start.pos)
    local to = pos_to_line_left(range['end'].pos)

    vim.api.nvim_buf_set_text(code_buf,
      from.line - 1, from.left, to.line - 1, to.left,
      { message.giveResult.str })

    load()

  elseif message.kind == 'HighlightingInfo' then
    update_pos_to_byte()

    for _, hl in ipairs(message.info.payload) do
      local from = pos_to_line_left(hl.range[1])
      local to = pos_to_line_left(hl.range[2])
      vim.api.nvim_buf_add_highlight(
        code_buf, hlns, 'agda' .. hl.atoms[1], from.line - 1, from.left, to.left
      )
    end

  elseif message.kind == 'ClearHighlighting' then
    vim.api.nvim_buf_clear_namespace(code_buf, hlns, 0, -1)

  elseif message.kind == 'RunningInfo' then
    print(message.message)

  -- else
  --   print(vim.inspect(message))

  end

  output.lock()
end

job = Job:new {
  command = 'agda',
  args = {'--interaction-json'},
  on_stdout = vim.schedule_wrap(receive)
}

return {
  start   = start,
  stop    = stop,
  test    = test,
  load    = load,
  case    = case,
  context = context,
  version = version,
  forward = forward,
  back    = back,
  window  = window,
  refine  = refine,
  auto    = auto,
}
