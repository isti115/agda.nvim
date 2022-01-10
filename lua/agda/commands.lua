local function make (filename, command)
  return string.format(
    'IOTCM "%s" NonInteractive Direct (%s)',
    filename, command
  )
end

local function make_interval (interval)
  return string.format(
    'Interval (Pn () %d %d %d) (Pn () %d %d %d)',
    interval.start.pos, interval.start.line, interval.start.col,
    interval['end'].pos, interval['end'].line, interval['end'].col
  )
end

local function make_range (filename, interval)
  return string.format(
    -- 'intervalsToRange Nothing [%s]',
    'intervalsToRange (Just (mkAbsolute "%s")) [%s]',
    filename, interval
  )
end

local function load (filename)
  return string.format(
    'Cmd_load "%s" []',
    filename
  )
end

local function version ()
  return string.format(
    'Cmd_show_version'
  )
end

local function auto (goal_id)
  return string.format(
    'Cmd_autoOne %d noRange ""',
    goal_id
  )
end

local function refine (goal_id)
  return string.format(
    'Cmd_refine_or_intro False %s noRange ""',
    goal_id
  )
end

local function case (goal_id, expression)
  return string.format(
    'Cmd_make_case %s noRange "%s"',
    goal_id, expression
  )
end

local function goal_type_context_infer (goal_id, content)
  return string.format(
    'Cmd_goal_type_context_infer Simplified %s noRange "%s"',
    goal_id, content
  )
end

local function goal_type_context (goal_id)
  return string.format(
    'Cmd_goal_type_context Simplified %s noRange ""',
    goal_id
  )
end

local function context (goal_id)
  return string.format(
    'Cmd_context Simplified %s noRange ""',
    goal_id
  )
end

local function give (goal_id, content, range)
  return string.format(
    -- 'Cmd_give WithoutForce %s noRange "%s"'
    'Cmd_give WithoutForce %s (%s) "%s"',
    goal_id, range, content
  )
end

return ({
  auto                    = auto                    ,
  case                    = case                    ,
  context                 = context                 ,
  give                    = give                    ,
  goal_type_context       = goal_type_context       ,
  goal_type_context_infer = goal_type_context_infer ,
  load                    = load                    ,
  make                    = make                    ,
  make_interval           = make_interval           ,
  make_range              = make_range              ,
  refine                  = refine                  ,
  version                 = version                 ,
})
