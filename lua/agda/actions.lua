local commands   = require('agda.commands')
local connection = require('agda.connection')
local output     = require('agda.output')
local state      = require('agda.state')
local utilities  = require('agda.utilities')

local function load ()
  state.code_buf = vim.api.nvim_get_current_buf()
  state.code_win = vim.api.nvim_get_current_win()

  output.initialize()

  vim.api.nvim_command('%s/?/{!  !}/ge') -- TODO silent instead of e?
  vim.api.nvim_command('noh') -- TODO find better solution
  vim.api.nvim_command('silent write')
  if not (connection.is_alive()) then connection.start() end
  output.initialize()
  connection.send(commands.make(
    utilities.current_file(),
    commands.load(utilities.current_file())
  ))
end

local function back ()
  if #state.goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end
  local previous, _ = utilities.find_surrounding_goals()
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
  if #state.goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end
  local _, next = utilities.find_surrounding_goals()
  vim.api.nvim_command(
    'normal ' ..
    next.range.start.line .. 'G' ..
    next.range.start.col + 2 .. '|'
  )
end

local function version ()
  connection.send(commands.make(
    utilities.current_file(),
    commands.version()
  ))
end

local function case ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to case split!'
    return
  end

  local expression = vim.fn.input('case: ')

  connection.send(commands.make(
    utilities.current_file(),
    commands.case(goal, expression)
  ))
end

local function auto ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to invoke auto!'
    return
  end

  connection.send(commands.make(
    utilities.current_file(),
    commands.auto(goal)
  ))
end

local function refine ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to refine!'
    return
  end

  connection.send(commands.make(
    utilities.current_file(),
    commands.refine(goal)
  ))
end

local function goal_type_context ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  connection.send(commands.make(
    utilities.current_file(),
    commands.goal_type_context(goal)
  ))
end

local function context ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  connection.send(commands.make(
    utilities.current_file(),
    commands.context(goal)
  ))
end

return {
  auto              = auto,
  back              = back,
  case              = case,
  goal_type_context = goal_type_context,
  context           = context,
  forward           = forward,
  load              = load,
  refine            = refine,
  version           = version,
}
