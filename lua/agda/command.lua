local function make (filename, payload)
  return 'IOTCM "' .. filename .. '" NonInteractive Indirect (' .. payload .. ')'
end

local function load (filename)
  return '(Cmd_load "' .. filename .. '" [])'
end

local function version ()
  return 'Cmd_show_version'
end

local function case (goal, expression)
  return 'Cmd_make_case ' .. goal .. ' noRange "' .. expression .. '"'
end

return ({
  load    = load,
  make    = make,
  case    = case,
  version = version,
})
