local state = {
  goals = nil,
  pos_to_byte = nil,
  code_buf = nil,
  code_win = nil,
  output_buf = nil,
  output_win = nil,
  hl_ns = nil
}

local utilities = require('agda.utilities')(state)

local function update_pos_to_byte ()
  state.pos_to_byte = utilities.character_to_byte_map(
    table.concat(vim.api.nvim_buf_get_lines(state.code_buf, 0, -1, false), '\n')
  )
end

return {
  state              = state,
  update_pos_to_byte = update_pos_to_byte,
}
