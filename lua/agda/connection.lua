local Job      = require('plenary.job')
local response = require('agda.response')

local handlers = {}

-- local function receive (error, data)
--   for _, h in ipairs(handlers) do
--     h(error, data)
--   end
-- end

local job = Job:new {
  command = 'agda',
  args = {'--interaction-json'},
  -- on_stdout = vim.schedule_wrap(receive)
  on_stdout = vim.schedule_wrap(response.handle)
}

-- local function start ()        job:start()               end
-- local function stop  ()        job:shutdown()            end
-- local function send  (message) job:send(message .. '\n') end
-- local function test  ()        print('pid: ', job.pid)   end

return {
  start      = function ()        job:start()                end,
  stop       = function ()        job:shutdown()             end,
  is_alive   = function ()        return not (not job.stdin) end,
  send       = function (message) job:send(message .. '\n')  end,
  addHandler = function (h)       table.insert(handlers, h)  end,
}
