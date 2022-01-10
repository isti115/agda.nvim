local state = require('agda.state')


--[[ Buffer and window operations ]]--

local function find_or_create_buf (name)
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    -- if vim.api.nvim_buf_get_name(b) == name then -- returns the whole path
    if vim.fn.bufname(b) == name then
      return b
    end
  end

  local new = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(new, name)
  return new
end

local function find_or_create_win (buf)
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then
      return w
    end
  end

  local tmp_win = vim.api.nvim_get_current_win() -- save previous window

  vim.cmd('1new') -- open a new window below the current one with minimal height
  local new = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(new, buf)

  vim.api.nvim_set_current_win(tmp_win) -- restore previous window

  return new
end

local function current_file ()
  -- vim.fn.expand('%')
  return vim.api.nvim_buf_get_name(state.code_buf)
end


--[[ Position manipulation ]]--

local function get_cursor_top_left (win)
  local position = vim.api.nvim_win_get_cursor(win)

  return {
    top = position[1] - 1,
    left = position[2],
  }
end

-- TODO: Is this not used anymore?
local function get_cursor_line_col (win)
  local position = vim.api.nvim_win_get_cursor(win)
  local line, col = position[1], position[2] + 1
  col = vim.fn.virtcol('.') -- Multi-byte workaround
  -- col = vim.api.nvim_eval('virtcol(".")') -- Multi-byte workaround
  -- https://www.reddit.com/r/agda/comments/qamibt/comment/hhjkp99
  return {
    line = line,
    col = col,
  }
end

local function is_before_line_col (a, b)
  return a.line < b.line or (a.line == b.line and a.col <= b.col)
end

local function is_before_top_left (a, b)
  return a.top < b.top or (a.top == b.top and a.left <= b.left)
end

local function character_to_byte_map (content)
  local position_map = {}
  local byte_map = {}
  for i = 1, #content do
    local b = string.byte(content, i)
    -- skip unicode continuation characters
    -- (https://en.wikipedia.org/wiki/UTF-8#Encoding)
    if not (0x80 <= b and b < 0xc0) then
      table.insert(position_map, i)
      byte_map[i] = #position_map
    end
  end
  -- add position index after last character for exclusive ranges
  table.insert(position_map, #content + 1)
  return position_map, byte_map
end

local function update_pos_to_byte ()
  state.pos_to_byte, state.byte_to_pos = character_to_byte_map(
    table.concat(vim.api.nvim_buf_get_lines(state.code_buf, 0, -1, false), '\n')
  )
end

local function byte_to_location (byte)
  local line = vim.fn.byte2line(byte)
  local left = byte - vim.fn.line2byte(line)
  return {
    top = line - 1,
    left = left,
    byte = byte
  }
end

local function pos_to_location (pos)
  return byte_to_location(state.pos_to_byte[pos])
end


--[[ Goal related ]]--

local function set_extmark (top, left, options)
  return vim.api.nvim_buf_set_extmark(
    state.code_buf, state.extmark_namespace, top, left, options
  )
end

local function get_extmark (id)
  local top, left = unpack(vim.api.nvim_buf_get_extmark_by_id(
    state.code_buf, state.extmark_namespace, id, {}
  ))

  return {
    top = top,
    left = left,
    byte = vim.api.nvim_buf_get_offset(state.code_buf, top) + left
  }
end

local function update_goal_location (goal)
  goal.location.from = get_extmark(goal.marks.from)
  goal.location.to = get_extmark(goal.marks.to)
end

local function update_goal_locations ()
  for _, g in pairs(state.goals) do
    update_goal_location(g)
  end
end

local function find_current_goal ()
  -- local line_col = get_cursor_line_col(state.code_win)
  update_goal_locations()
  local top_left = get_cursor_top_left(state.code_win)

  for _, g in pairs(state.goals) do
    if  is_before_top_left(g.location.from, top_left)
    and is_before_top_left(top_left, g.location.to)
    then
       return g
    end
  end
end

local function get_goal_content (goal)
  update_goal_location(goal)

  local text = vim.api.nvim_buf_get_lines(
    state.code_buf,
    goal.location.from.top,
    goal.location.to.top + 1,
    false
  )

  local content = string.sub(
    text[1],
    goal.location.from.left + 3,
    goal.location.to.left - 2
  )

  return content
end

local function get_goal_interval (goal)
  update_goal_location(goal)

  -- local from_line_start = vim.api.nvim_buf_get_offset(
  --   state.code_buf,
  --   goal.location.from.top
  -- )
  --
  -- local to_line_start = vim.api.nvim_buf_get_offset(
  --   state.code_buf,
  --   goal.location.from.top
  -- )

  -- print(offset , goal.location.from.left)


  -- local content = get_goal_content(goal)
  -- local pad = #string.gsub(content, '^(%s*).*', '%1')
  -- local hack = from_line_start + goal.location.from.left + 1 + pad

  -- TODO Check this (bytes need conversion to pos)
  -- return {
  --   start = {
  --     col = goal.location.from.left,
  --     line = goal.location.from.top + 1,
  --     pos = state.byte_to_pos[goal.location.from.byte] + 1,
  --     -- pos = from_line_start + goal.location.from.left + 1,
  --     -- pos = hack,
  --   },
  --   ['end'] = {
  --     col = goal.location.to.left,
  --     line = goal.location.to.top + 1,
  --     pos = state.byte_to_pos[goal.location.to.byte],
  --     -- pos = to_line_start + goal.location.to.left,
  --   }
  -- }

  return goal.range
end

local function find_surrounding_goals ()
  -- local line_col = get_cursor_line_col(state.code_win)
  update_goal_locations()
  local top_left = get_cursor_top_left(state.code_win)

  if #state.goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end

  local sortedGoals = {}
  for _, g in pairs(state.goals) do
    table.insert(sortedGoals, g)
  end

  table.sort(sortedGoals, function (a, b) return a.location.from.byte < b.location.from.byte end)

  -- local previous = state.goals[#state.goals]
  -- local next = state.goals[1]
  local previous = sortedGoals[#sortedGoals]
  local next = sortedGoals[1]

  -- for _, g in pairs(state.goals) do -- TODO Is the order deterministic?
  for _, g in ipairs(sortedGoals) do -- TODO Is the order deterministic?
    if is_before_top_left(g.location.to, top_left) then
      previous = g
    elseif is_before_top_left(top_left, g.location.from) then
      next = g
      return previous, next
    end
  end

  return previous, next
end


--[[ Text manipulation ]]--

-- Needed because of: https://github.com/agda/agda/issues/5665
local function remove_qualifications (input)
  -- TODO Handle linebreaks properly with indentation:
  local oneLine = string.gsub(string.gsub(input, '\n', ' '), ' +', ' ')
  local unqualified = string.gsub(oneLine, '[^ ()]-%.', '')
  return unqualified
end

local function trim_start(input)
   local trimmed = string.gsub(input, "^%s*(.-)$", "%1")
   return trimmed
end

local function trim(input)
   local trimmed = string.gsub(input, "^%s*(.-)%s*$", "%1")
   return trimmed
end


--[[ Logging ]]--

local function log(content, name)
  local out = io.open('/tmp/agda.nvim.log','a')
  local mark = name and ' "' .. name .. '"' or ''
  out:write('-----[ Log Event' .. mark .. ' @ ' .. os.date() .. ' ]-----\n')
  out:write(vim.inspect(content) .. '\n')
  io.close(out)
end


return {
  find_or_create_buf     = find_or_create_buf     ,
  find_or_create_win     = find_or_create_win     ,
  current_file           = current_file           ,

  get_cursor_top_left    = get_cursor_top_left    ,
  get_cursor_line_col    = get_cursor_line_col    ,
  is_before_top_left     = is_before_top_left     ,
  is_before_line_col     = is_before_line_col     ,
  character_to_byte_map  = character_to_byte_map  ,
  update_pos_to_byte     = update_pos_to_byte     ,
  byte_to_location       = byte_to_location       ,
  pos_to_location        = pos_to_location        ,

  set_extmark            = set_extmark            ,
  get_extmark            = get_extmark            ,
  update_goal_location   = update_goal_location   ,
  update_goal_locations  = update_goal_locations  ,
  find_surrounding_goals = find_surrounding_goals ,
  find_current_goal      = find_current_goal      ,
  get_goal_content       = get_goal_content       ,
  get_goal_interval      = get_goal_interval      ,

  remove_qualifications  = remove_qualifications  ,
  trim_start             = trim_start             ,
  trim                   = trim                   ,

  log                    = log                    ,
}
