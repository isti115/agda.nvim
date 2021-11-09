local function make (filename, command)
  return 'IOTCM "' .. filename .. '" NonInteractive Direct (' .. command .. ')'
end

local function load (filename)
  return 'Cmd_load "' .. filename .. '" []'
end

local function version ()
  return 'Cmd_show_version'
end

local function auto (goal)
  return 'Cmd_autoOne ' .. goal .. ' noRange ""'
end

local function refine (goal)
  return 'Cmd_refine_or_intro False ' .. goal .. ' noRange ""'
end

local function case (goal, expression)
  return 'Cmd_make_case ' .. goal .. ' noRange "' .. expression .. '"'
end

local function goal_type_context_infer (goal, content)
  return 'Cmd_goal_type_context_infer Simplified ' .. goal .. ' noRange "' .. content .. '"'
end

local function goal_type_context (goal)
  return 'Cmd_goal_type_context Simplified ' .. goal .. ' noRange ""'
end

local function context (goal)
  return 'Cmd_context Simplified ' .. goal .. ' noRange ""'
end

local function give (goal, content)
  return 'Cmd_give WithoutForce ' .. goal .. ' noRange "' .. content .. '"'
end

return ({
  auto              = auto,
  case              = case,
  goal_type_context_infer = goal_type_context_infer,
  goal_type_context = goal_type_context,
  context           = context,
  load              = load,
  make              = make,
  give              = give,
  refine            = refine,
  version           = version,
})
