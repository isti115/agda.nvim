local commands   = require('agda.commands')
local connection = require('agda.connection')
local enums      = require('agda.enums')
local output     = require('agda.output')
local state      = require('agda.state')
local utilities  = require('agda.utilities')

local function load ()
  state.code_buf = vim.api.nvim_get_current_buf()
  state.code_win = vim.api.nvim_get_current_win()

  state.status = enums.Status.EMPTY
  state.offsets = {}
  state.originalGoalSizes = {}
  output.initialize()

  -- vim.api.nvim_command( -- TODO do this with goal info in mind?
  --   ':%s/\\(^\\|\\s\\|[({]\\)\\zs?\\ze\\(\\s\\|$\\|[)}]\\)/{!   !}/ge'
  -- ) -- TODO silent instead of e?
  -- vim.api.nvim_command('noh') -- TODO find better solution
  vim.api.nvim_command('silent write')

  if not (connection.is_alive()) then connection.start() end
  connection.send(commands.make(
    utilities.current_file(),
    commands.load(utilities.current_file())
  ))
end

local function back ()
  if state.status ~= enums.Status.READY then
    print('Please load the file first!')
    return
  end
  if #state.goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end
  local previous, _ = utilities.find_surrounding_goals()
  vim.api.nvim_win_set_cursor(
    state.code_win,
    { previous.location.from.top + 1, previous.location.from.left + 3 }
  )
  -- vim.api.nvim_command(
  --   'normal ' ..
  --   previous.range.start.line .. 'G' ..
  --   previous.range.start.col + 2 .. '|'
  -- )
end

local function forward ()
  if state.status ~= enums.Status.READY then
    print('Please load the file first!')
    return
  end
  if #state.goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end

  local _, next = utilities.find_surrounding_goals()
  vim.api.nvim_win_set_cursor(
    state.code_win,
    { next.location.from.top + 1, next.location.from.left + 3 }
  )
  -- vim.api.nvim_command(
  --   'normal ' ..
  --   next.range.start.line .. 'G' ..
  --   next.range.start.col + 2 .. '|'
  -- )
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
    commands.case(goal.id, expression)
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
    commands.auto(goal.id)
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
    commands.refine(goal.id)
  ))
end

local function goal_type_context_infer ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  local content = utilities.get_goal_content(goal)

  connection.send(commands.make(
    utilities.current_file(),
    commands.goal_type_context_infer(goal.id, content)
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
    commands.goal_type_context(goal.id)
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
    commands.context(goal.id)
  ))
end

local function give ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  -- local content = utilities.trim(utilities.get_goal_content(goal)) -- TODO
  local content = utilities.get_goal_content(goal)
  local interval = utilities.get_goal_interval(goal)

  connection.send(commands.make(
    utilities.current_file(),
    commands.give(
      goal.id,
      content,
      commands.make_range(
        utilities.current_file(),
        commands.make_interval(interval)
      )
    )
  ))
end

local function clear ()
  vim.api.nvim_buf_clear_namespace(
    state.code_buf,
    state.extmark_namespace,
    0, -1
  )

  vim.api.nvim_buf_clear_namespace(
    state.code_buf,
    state.highlight_namespace,
    0, -1
  )
end

return {
  auto                    = auto                    ,
  back                    = back                    ,
  case                    = case                    ,
  clear                   = clear                   ,
  goal_type_context_infer = goal_type_context_infer ,
  goal_type_context       = goal_type_context       ,
  context                 = context                 ,
  give                    = give                    ,
  forward                 = forward                 ,
  load                    = load                    ,
  refine                  = refine                  ,
  version                 = version                 ,
}
