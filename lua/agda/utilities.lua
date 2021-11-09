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
  for i = 1, #content do
    local b = string.byte(content, i)
    -- skip unicode continuation characters
    -- (https://en.wikipedia.org/wiki/UTF-8#Encoding)
    if not (0x80 <= b and b < 0xc0) then
      table.insert(position_map, i)
    end
  end
  -- add position index after last character for exclusive ranges
  table.insert(position_map, #content + 1)
  return position_map
end

local function update_pos_to_byte ()
  state.pos_to_byte = character_to_byte_map(
    table.concat(vim.api.nvim_buf_get_lines(state.code_buf, 0, -1, false), '\n')
  )
end

local function byte_to_line_left (byte)
  local line = vim.fn.byte2line(byte)
  local left = byte - vim.fn.line2byte(line)
  return {
    line = line,
    left = left,
  }
end

local function pos_to_line_left (pos)
  return byte_to_line_left(state.pos_to_byte[pos])
end


--[[ Goal related ]]--

local function update_goal_locations ()
  for _, g in pairs(state.goals) do
    local from = vim.api.nvim_buf_get_extmark_by_id(
      state.code_buf, state.namespace, g.marks.from, {}
    )
    local to = vim.api.nvim_buf_get_extmark_by_id(
      state.code_buf, state.namespace, g.marks.to, {}
    )

    g.location.from.top = from[1]
    g.location.from.left = from[2]

    g.location.to.top = to[1]
    g.location.to.left = to[2]

    -- print(vim.inspect(g.location))
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
       return g.id
    end
  end
end

local function find_surrounding_goals ()
  -- local line_col = get_cursor_line_col(state.code_win)
  update_goal_locations()
  local top_left = get_cursor_top_left(state.code_win)

  if #state.goals == 0 then
    print('There are no goals in the currently loaded buffer.')
    return
  end

  local previous = state.goals[#state.goals]
  local next = state.goals[1]

  for _, g in ipairs(state.goals) do
    if is_before_top_left(g.location.to, top_left) then
      previous = g
    elseif is_before_top_left(top_left, g.location.from) then
      next = g
      return previous, next
    end
  end

  return previous, next
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
  byte_to_line_left      = byte_to_line_left      ,
  pos_to_line_left       = pos_to_line_left       ,

  update_goal_locations  = update_goal_locations  ,
  find_surrounding_goals = find_surrounding_goals ,
  find_current_goal      = find_current_goal      ,
}
