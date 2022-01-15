local enums     = require('agda.enums')
local output    = require('agda.output')
local state     = require('agda.state')
local utilities = require('agda.utilities')

-- local expanded_goal = '{!   !}  ' -- TODO Hack to avoid virtual text overlap
local expanded_goal = '{!   !}'

local function handle (_, data)
  output.unlock()
  local message = vim.fn.json_decode(
    string.sub(data, 1, 5) == 'JSON>' and string.sub(data, 6) or data
  )

  -- print(vim.inspect(message))
  if message.kind ~= 'HighlightingInfo' then
    utilities.log(message)
  end

  if message.kind == 'DisplayInfo' then
    if message.info.kind == 'AllGoalsWarnings' then
      -- Preparation
      utilities.update_pos_to_byte()
      utilities.update_goal_locations()

      -- Cleanup
      output.clear()

      local needs_expansion = {}

      for _, g in ipairs(message.info.visibleGoals) do
        local id = g.constraintObj.id
        local range = g.constraintObj.range[1]
        local from_byte = state.pos_to_byte[range.start.pos]
        local to_byte = state.pos_to_byte[range['end'].pos]

        if state.paren then
          from_byte = from_byte + 1
          to_byte = to_byte + 1
        end

        -- local from = utilities.pos_to_location(range.start.pos)
        -- local to = utilities.pos_to_location(range['end'].pos)
        local from = utilities.byte_to_location(from_byte)
        local to = utilities.byte_to_location(to_byte)

        if not state.goals[id] then
          local fromId = utilities.set_extmark(from.top, from.left, {})
          local toId = utilities.set_extmark(
            to.top, to.left,
            {
              virt_text_pos = 'overlay',
              virt_text_hide = true,
              virt_text = {{'?' .. id, 'agdaholenumber'}},
              -- hl_mode = '?', -- TODO Don't affect goal number background
              right_gravity = false,
            }
          )

          local newGoal = {
            id = id,
            type = g.type,
            marks = {
              from = fromId,
              to = toId,
            },
            location = {}
          }

          state.goals[id] = newGoal

          if from_byte + 1 == to_byte then
            table.insert(needs_expansion, newGoal)
          end
        else
          state.goals[id].type = g.type
        end
      end

      for _, g in ipairs(needs_expansion) do
        local from = utilities.get_extmark(g.marks.from)
        local to   = utilities.get_extmark(g.marks.to)

        vim.api.nvim_buf_set_text(
          state.code_buf,
          from.top, from.left, to.top, to.left,
          {expanded_goal}
        )

        utilities.set_extmark(from.top, from.left, { id = g.marks.from, })
        utilities.set_extmark(from.top, from.left + #expanded_goal, {
          id = g.marks.to,
          virt_text_pos = 'overlay',
          virt_text_hide = true,
          virt_text = {{'?' .. g.id, 'agdaholenumber'}},
          -- hl_mode = '?', -- TODO Don't affect goal number background
          right_gravity = false,
        })
      end

      output.print_goals(state.goals)
      output.fit_height()
      output.reset_cursor()
      state.status = enums.Status.READY


    elseif message.info.kind == 'GoalSpecific' then
      output.clear()

      if message.info.goalInfo.kind == 'GoalType' then
        -- if message.info.goalInfo.typeAux.kind == 'GoalAndHave' or
        --    message.info.goalInfo.typeAux.kind == 'GoalOnly' then
        output.buf_print(
          'Goal: ' .. utilities.remove_qualifications(
            message.info.goalInfo.type
          )
        )
        --end

        if message.info.goalInfo.typeAux.kind == 'GoalAndHave' then
          output.buf_print(
            'Have: ' .. utilities.remove_qualifications(
              message.info.goalInfo.typeAux.expr
            )
          )
        end

        if #message.info.goalInfo.entries > 0 then
          output.buf_print('-----')
          output.buf_print('Context:')

          output.print_context(message.info.goalInfo.entries)
        end

      elseif message.info.goalInfo.kind == 'InferredType' then
        output.buf_print(message.info.goalInfo.expr)

      elseif message.info.goalInfo.kind == 'NormalForm' then
        output.buf_print(message.info.goalInfo.expr)

      end

      output.fit_height()
      output.reset_cursor()

    elseif message.info.kind == 'Context' then
      output.clear()
      output.print_context(message.info.context)
      output.fit_height()
      output.reset_cursor()

    elseif message.info.kind == 'InferredType' then
      output.clear()
      output.buf_print(message.info.expr)
      output.fit_height()
      output.reset_cursor()

    elseif message.info.kind == 'NormalForm' then
      output.clear()
      output.buf_print(message.info.expr)
      output.fit_height()
      output.reset_cursor()

    elseif message.info.kind == 'Version' then
      output.set_lines(0, -1, { 'Agda version:', message.info.version })
      output.fit_height()

    elseif message.info.kind == 'Error' then
      -- print('Error: ' .. message.info.error.message)
      output.clear()
      output.buf_print(message.info.error.message)
      output.fit_height()
      output.reset_cursor()

    end

  elseif message.kind == 'MakeCase' then
    vim.api.nvim_buf_set_lines(
      state.code_buf,
      message.interactionPoint.range[1].start.line - 1,
      message.interactionPoint.range[1]['end'].line,
      false, message.clauses
    )

    require('agda').load()

  elseif message.kind == 'GiveAction' then
    utilities.update_pos_to_byte()
    utilities.update_goal_locations()
    -- local range = message.interactionPoint.range[1]
    -- local from = utilities.pos_to_line_left(range.start.pos)
    -- local to = utilities.pos_to_line_left(range['end'].pos)
    local goal = state.goals[message.interactionPoint.id]
    local from = goal.location.from
    local to = goal.location.to

    local content = utilities.trim(utilities.get_goal_content(goal))

    local newContent
      =   message.giveResult.str
      and utilities.remove_qualifications(message.giveResult.str)
      or  message.giveResult.paren
      and '(' .. content .. ')'
      or  true -- fallback / else
      and content

    vim.api.nvim_buf_set_text(
      state.code_buf,
      from.top, from.left, to.top, to.left,
      { newContent }
      -- { utilities.trim(newContent) }
      -- { utilities.trim_start(newContent) }
      -- TODO alignment hack to keep byte positions
      -- { '  ' .. newContent .. '  ' }
      -- { '  ' .. utilities.trim_start(newContent) .. '  ' }
    )

    state.paren = message.giveResult.paren

    utilities.del_extmark(goal.marks.from)
    utilities.del_extmark(goal.marks.to)

    state.goals[goal.id] = nil

    utilities.update_pos_to_byte()

    -- vim.api.nvim_buf_del_extmark(
    --   state.code_buf, state.namespace,
    --   state.goals[message.interactionPoint.id + 1].marks.from
    -- )
    -- vim.api.nvim_buf_del_extmark(
    --   state.code_buf, state.namespace,
    --   state.goals[message.interactionPoint.id + 1].marks.to
    -- )

    -- require('agda').load()

  elseif message.kind == 'HighlightingInfo' then
    utilities.update_pos_to_byte()

    for _, hl in ipairs(message.info.payload) do
      if #hl.atoms ~= 0 and state.pos_to_byte[hl.range[2]] then
        -- TODO why is this sometimes empty or way out of the files range? 🤔
        local from = utilities.pos_to_location(hl.range[1])
        local to   = utilities.pos_to_location(hl.range[2])
        vim.api.nvim_buf_add_highlight(
          state.code_buf, state.highlight_namespace,
          'agda' .. hl.atoms[1], from.top, from.left, to.left
        )
      end
    end

  elseif message.kind == 'ClearHighlighting' then
    vim.api.nvim_buf_clear_namespace(
      state.code_buf,
      state.highlight_namespace,
      0, -1
    )

  elseif message.kind == 'ClearRunningInfo' then
    output.clear()

  elseif message.kind == 'RunningInfo' then
    output.buf_print(message.message)
    output.fit_height()
    output.reset_cursor()

  -- else
  --   print(vim.inspect(message))

  end

  output.lock()
end

return {
  handle = handle ,
}
