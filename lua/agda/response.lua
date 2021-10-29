local output  = require('agda.output')
local store   = require('agda.store')
-- local actions = require('agda.actions') -- causes circular dependency

local state = store.state
local utilities = require('agda.utilities')(state)

local function handle (_, data)
  output.unlock()
  local message = vim.fn.json_decode(
    string.sub(data, 1, 5) == 'JSON>' and string.sub(data, 6) or data
  )

  -- print(vim.inspect(message))
  if message.kind == 'DisplayInfo' then
    if message.info.kind == 'AllGoalsWarnings' then
      output.clear()
      state.goals = {}

      output.set_height(#message.info.visibleGoals)
      for _, g in ipairs(message.info.visibleGoals) do
        table.insert(state.goals, {
          id = g.constraintObj.id,
          type = g.type,
          range = g.constraintObj.range[1],
        })
      end

      output.print_goals(state.goals)

    elseif message.info.kind == 'Context' then
      -- print(vim.inspect(message))
      output.clear()

      output.set_height(#message.info.context)
      for _, c in ipairs(message.info.context) do
        -- set_lines(i - 1, i - 1, { c.reifiedName .. ' : ' .. c.binding })
        output.buf_print(c.reifiedName .. ' : ' .. c.binding)
      end

    elseif message.info.kind == 'Version' then
      output.set_lines(0, -1, { 'Agda version:', message.info.version })
      output.set_height(2)

    elseif message.info.kind == 'Error' then
      print('Error: ' .. message.info.error.message)

    end

  elseif message.kind == 'MakeCase' then
    vim.api.nvim_buf_set_lines(state.code_buf,
      message.interactionPoint.range[1].start.line - 1,
      message.interactionPoint.range[1]['end'].line,
      false, message.clauses)

    -- actions.load() -- causes circular dependency

  elseif message.kind == 'GiveAction' then
    store.update_pos_to_byte()
    local range = message.interactionPoint.range[1]
    local from = utilities.pos_to_line_left(range.start.pos)
    local to = utilities.pos_to_line_left(range['end'].pos)

    vim.api.nvim_buf_set_text(state.code_buf,
      from.line - 1, from.left, to.line - 1, to.left,
      { message.giveResult.str })

    -- actions.load() -- causes circular dependency

  elseif message.kind == 'HighlightingInfo' then
    store.update_pos_to_byte()

    for _, hl in ipairs(message.info.payload) do
      local from = utilities.pos_to_line_left(hl.range[1])
      local to = utilities.pos_to_line_left(hl.range[2])
      vim.api.nvim_buf_add_highlight(
        state.code_buf, state.hl_ns, 'agda' .. hl.atoms[1], from.line - 1, from.left, to.left
      )
    end

  elseif message.kind == 'ClearHighlighting' then
    vim.api.nvim_buf_clear_namespace(state.code_buf, state.hl_ns, 0, -1)

  elseif message.kind == 'RunningInfo' then
    print(message.message)

  -- else
  --   print(vim.inspect(message))

  end

  output.lock()
end

return {
  handle = handle
}
