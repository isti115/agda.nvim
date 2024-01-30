local commands   = require('agda.commands')
local connection = require('agda.connection')
local enums      = require('agda.enums')
local output     = require('agda.output')
local state      = require('agda.state')
local utilities  = require('agda.utilities')

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

local function load ()
  state.code_buf = vim.api.nvim_get_current_buf()
  state.code_win = vim.api.nvim_get_current_win()

  state.status = enums.Status.EMPTY
  state.goals = {}
  state.paren = nil
  output.initialize()
  clear()

  vim.api.nvim_command('silent write')

  if not (connection.is_alive()) then connection.start() end
  connection.send(commands.make(
    utilities.current_file(),
    commands.load(utilities.current_file())
  ))
end

local function back ()
  if not utilities.ensure_loaded() then return end
  if not utilities.ensure_goals() then return end

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
  if not utilities.ensure_loaded() then return end
  if not utilities.ensure_goals() then return end

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

  local expression = utilities.get_goal_content_or_prompt(goal, 'case: ')

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

  local content = utilities.get_goal_content_or_prompt(goal, 'have: ')

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

local function goal_type_context_norm ()
  local goal = utilities.find_current_goal()
  if not goal then
    print 'Place the cursor in a goal to get the context!'
    return
  end

  connection.send(commands.make(
    utilities.current_file(),
    commands.goal_type_context_norm(goal.id)
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

  local content = utilities.get_goal_content_or_prompt(goal, 'give: ')
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

local function compute ()
  local goal = utilities.find_current_goal()

  if not goal then
    local expression = vim.fn.input('compute: ')
    connection.send(commands.make(
      utilities.current_file(),
      commands.compute_toplevel(enums.ComputeMode.DEFAULT_COMPUTE, expression)
    ))
  else
    local expression = utilities.get_goal_content_or_prompt(goal, 'compute: ')
    connection.send(commands.make(
      utilities.current_file(),
      commands.compute(enums.ComputeMode.DEFAULT_COMPUTE, goal.id, expression)
    ))
  end
end

local function infer ()
  local goal = utilities.find_current_goal()

  if not goal then
    local expression = vim.fn.input('infer: ')
    connection.send(commands.make(
      utilities.current_file(),
      commands.infer_toplevel(enums.Rewrite.SIMPLIFIED, expression)
    ))
  else
    local expression = utilities.get_goal_content_or_prompt(goal, 'infer: ')
    connection.send(commands.make(
      utilities.current_file(),
      commands.infer(enums.Rewrite.SIMPLIFIED, goal.id, expression)
    ))
  end
end

local function goals ()
  output.unlock()
  output.clear()
  output.print_goals(state.goals)
  output.fit_height()
  output.reset_cursor()
  output.lock()
end

return {
  auto                    = auto                     ,
  back                    = back                     ,
  case                    = case                     ,
  clear                   = clear                    ,
  compute                 = compute                  ,
  context                 = context                  ,
  forward                 = forward                  ,
  give                    = give                     ,
  goal_type_context       = goal_type_context        ,
  goal_type_context_norm  = goal_type_context_norm   ,
  goal_type_context_infer = goal_type_context_infer  ,
  goals                   = goals                    ,
  infer                   = infer                    ,
  load                    = load                     ,
  refine                  = refine                   ,
  version                 = version                  ,
}
