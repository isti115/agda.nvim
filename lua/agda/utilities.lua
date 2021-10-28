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

  vim.cmd('1new') -- open a new window below the current one with minimal height
  local new = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(new, buf)

  return new
end

local function get_cursor_position (win)
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

local function is_before (a, b)
  return a.line < b.line or (a.line == b.line and a.col <= b.col)
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

local function byte_to_line_left (byte)
  local line = vim.fn.byte2line(byte)
  local left = byte - vim.fn.line2byte(line)
  return {
    line = line,
    left = left,
  }
end

return {
  find_or_create_buf    = find_or_create_buf,
  find_or_create_win    = find_or_create_win,
  get_cursor_position   = get_cursor_position,
  is_before             = is_before,
  character_to_byte_map = character_to_byte_map,
  byte_to_line_left     = byte_to_line_left,
}
