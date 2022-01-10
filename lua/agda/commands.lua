-- TODO Rewrite these using string.format

local function make (filename, command)
  return 'IOTCM "' .. filename .. '" NonInteractive Direct (' .. command .. ')'
end

local function make_interval (interval)
  return 'Interval (Pn () ' .. interval.start.pos .. ' ' .. interval.start.line .. ' ' .. interval.start.col .. ') (Pn () ' .. interval['end'].pos .. ' ' .. interval['end'].line .. ' ' .. interval['end'].col .. ')'
end

local function make_range (filename, interval)
  return 'intervalsToRange (Just (mkAbsolute "' .. filename .. '")) [' .. interval .. ']'
  -- return 'intervalsToRange Nothing [' .. interval .. ']'
end

local function load (filename)
  return 'Cmd_load "' .. filename .. '" []'
end

local function version ()
  return 'Cmd_show_version'
end

local function auto (goal_id)
  return 'Cmd_autoOne ' .. goal_id .. ' noRange ""'
end

local function refine (goal_id)
  return 'Cmd_refine_or_intro False ' .. goal_id .. ' noRange ""'
end

local function case (goal_id, expression)
  return 'Cmd_make_case ' .. goal_id .. ' noRange "' .. expression .. '"'
end

local function goal_type_context_infer (goal_id, content)
  return 'Cmd_goal_type_context_infer Simplified ' .. goal_id .. ' noRange "' .. content .. '"'
end

local function goal_type_context (goal_id)
  return 'Cmd_goal_type_context Simplified ' .. goal_id .. ' noRange ""'
end

local function context (goal_id)
  return 'Cmd_context Simplified ' .. goal_id .. ' noRange ""'
end

local function give (goal_id, content, range)
  -- return 'Cmd_give WithoutForce ' .. goal_id .. ' noRange "' .. content .. '"'
  return 'Cmd_give WithoutForce ' .. goal_id .. ' (' .. range .. ') "' .. content .. '"'
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
