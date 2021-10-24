local function make (filename, payload)
  return 'IOTCM "' .. filename .. '" NonInteractive Direct (' .. payload .. ')'
end

local function load (filename)
  return 'Cmd_load "' .. filename .. '" []'
end

local function version ()
  return 'Cmd_show_version'
end

local function case (goal, expression)
  return 'Cmd_make_case ' .. goal .. ' noRange "' .. expression .. '"'
end

local function context (goal)
  return 'Cmd_context Simplified ' .. goal .. ' noRange ""'
end

return ({
  case    = case,
  context = context,
  load    = load,
  make    = make,
  version = version,
})
