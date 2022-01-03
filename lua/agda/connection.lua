local Job      = require('plenary.job')
local response = require('agda.response')

local job

local function start    ()        job:start()                end
local function stop     ()        job:shutdown()             end
local function is_alive ()        return not (not job.stdin) end
local function send     (message) job:send(message .. '\n')  end

job = Job:new {
  command = 'agda',
  args = {'--interaction-json'},
  on_stdout = vim.schedule_wrap(response.handle)
}

return {
  is_alive = is_alive,
  send     = send    ,
  start    = start   ,
  stop     = stop    ,
}
