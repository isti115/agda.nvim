local enums     = require('agda.enums')
local output    = require('agda.output')
local state     = require('agda.state')
local utilities = require('agda.utilities')

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
      utilities.update_pos_to_byte()
      output.clear()
      state.goals = {}

      vim.api.nvim_buf_clear_namespace(
        state.code_buf,
        state.extmark_namespace,
        0, -1
      )

      local needsExpansion = {}

      for _, g in ipairs(message.info.visibleGoals) do
        local range = g.constraintObj.range[1]
        local from_byte = state.pos_to_byte[range.start.pos]
        local to_byte = state.pos_to_byte[range['end'].pos]

        -- TODO This is just a hack to fix offsets caused by giving
        for _, o in ipairs(state.offsets) do
          if o.byte < from_byte then -- TODO or less than?
            from_byte = from_byte - o.length
          end
          if o.byte < to_byte then -- TODO or less than?
            to_byte = to_byte - o.length
          end
        end

        -- local from = utilities.pos_to_location(range.start.pos)
        -- local to = utilities.pos_to_location(range['end'].pos)
        local from = utilities.byte_to_location(from_byte)
        local to = utilities.byte_to_location(to_byte)

        local fromId = utilities.set_extmark(from.top, from.left, {})
        local toId = utilities.set_extmark(
          to.top, to.left,
          {
            hl_group = 'agdakeyword', -- TODO this doesn't seem to work
            virt_text_pos = 'overlay',
            virt_text_hide = true,
            virt_text = {{'?' .. g.constraintObj.id}},
            right_gravity = false,
          }
        )

        local newGoal = {
          id = g.constraintObj.id,
          type = g.type,
          marks = {
            from = fromId,
            to = toId,
          },
          location = {},
          range = range
        }

        -- table.insert(state.goals, newGoal)
        state.goals[newGoal.id] = newGoal

        if from.top == to.top and from.left + 1 == to.left then
          table.insert(needsExpansion, newGoal)
        end
      end

      -- for _, p in ipairs(state.pending) do
      --   p()
      -- end
      -- state.pending = {}

      for _, g in ipairs(needsExpansion) do
        local from = utilities.get_extmark(g.marks.from)
        local to   = utilities.get_extmark(g.marks.to)
        vim.api.nvim_buf_set_text(
          state.code_buf,
          from.top, from.left, to.top, to.left,
          {'{!   !}  '} -- TODO Hack to avoid virtual text overlap
        )
        utilities.set_extmark(from.top, from.left, { id = g.marks.from, })
        utilities.set_extmark(to.top, to.left + 6, {
          id = g.marks.to,
          hl_group = 'agdakeyword', -- TODO this doesn't seem to work
          virt_text_pos = 'overlay',
          virt_text_hide = true,
          virt_text = {{'?' .. g.id}},
          right_gravity = false,
        })
      end

      utilities.update_goal_locations()
      -- if state.status == enums.Status.EMPTY then
      for _, g in pairs(state.goals) do
        if not state.originalGoalSizes[g.id] then
          state.originalGoalSizes[g.id] = (
            g.location.to.left - g.location.from.left -- inclusive => +2
          )
        end
      end
      -- end

      output.print_goals(state.goals)
      output.fit_height()
      output.reset_cursor()
      state.status = enums.Status.READY


    elseif message.info.kind == 'GoalSpecific' then
      output.clear()

      output.buf_print(
        'Goal: ' .. utilities.remove_qualifications(
          message.info.goalInfo.type
        )
      )

      if message.info.goalInfo.typeAux.kind == "GoalAndHave" then
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

      output.fit_height()
      output.reset_cursor()

    elseif message.info.kind == 'Context' then
      output.clear()
      output.print_context(message.info.context)
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

    local newContent
      =   message.giveResult.str
      and utilities.remove_qualifications(message.giveResult.str)
      or  message.giveResult.paren
      and '(' .. utilities.get_goal_content(goal) .. ')'
      or  true -- fallback / else
      and utilities.get_goal_content(goal)

    newContent = utilities.trim(newContent) -- TODO Should this be done by Agda?

    table.insert(state.offsets, {
      byte = to.byte,
      -- length = (to.left - from.left) - #newContent
      length = state.originalGoalSizes[goal.id] - #newContent
    })

    -- table.insert(state.pending, function ()
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
    -- end)

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
