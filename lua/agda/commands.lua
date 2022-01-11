local function make (filename, command)
  return string.format(
    'IOTCM "%s" NonInteractive Direct (%s)',
    filename, command
  )
end

local function make_point(point)
  return string.format(
    'Pn () %d %d %d',
    point.pos, point.line, point.col
  )
end

local function make_interval (interval)
  return string.format(
    'Interval (%s) (%s)',
    make_point(interval.start), make_point(interval['end'])
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
    'Cmd_give WithoutForce %d (%s) "%s"',
    goal_id, range, content
  )
end

local function compute (mode, goal_id, expression)
  return string.format(
    'Cmd_compute %s %d noRange "%s"',
    mode, goal_id, expression
  )
end

local function compute_toplevel (mode, expression)
  return string.format(
    'Cmd_compute_toplevel %s "%s"',
    mode, expression
  )
end

local function infer (mode, goal_id, expression)
  return string.format(
    'Cmd_infer %s %d noRange "%s"',
    mode, goal_id, expression
  )
end

local function infer_toplevel (mode, expression)
  return string.format(
    'Cmd_infer_toplevel %s "%s"',
    mode, expression
  )
end

return ({
  auto                    = auto                    ,
  case                    = case                    ,
  compute                 = compute                 ,
  compute_toplevel        = compute_toplevel        ,
  context                 = context                 ,
  give                    = give                    ,
  goal_type_context       = goal_type_context       ,
  goal_type_context_infer = goal_type_context_infer ,
  infer                   = infer                   ,
  infer_toplevel          = infer_toplevel          ,
  load                    = load                    ,
  make                    = make                    ,
  make_interval           = make_interval           ,
  make_range              = make_range              ,
  refine                  = refine                  ,
  version                 = version                 ,
})
