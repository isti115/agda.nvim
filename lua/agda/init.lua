--[[
  Agda interaction plugin for NeoVim written in Lua
  István Donkó (Isti115@GitHub)
  Copyright (C) 2021

  Terminology:
    + nvim:
      - top  : row number starting from zero
      - left : byte offset from the beginning of the line
      - byte : byte offset from the beginning of the file

      - location : { from = { top, left }, to = { top, left } } -- TODO: span

    + Agda:
      - line : row number starting from one
      - col  : character offset from the beginning of the line
      - pos  : character offset from the beginning of the file

      - range : [ { start = { pos, col, line }, end = { pos, col, line } } ]

  Notes:
    * Agda uses `start` and `end` for the limits of ranges,
      but `end` is a reserved keyword in Lua...
--]]


local actions    = require('agda.actions')
local connection = require('agda.connection')
local enums      = require('agda.enums')
local output     = require('agda.output')
local state      = require('agda.state')

local function test ()
  -- print(vim.inspect(state.pos_to_byte))
  -- print(vim.inspect(state.originalGoalSizes), vim.inspect(state.offsets))
  -- print(tostring(state.status))
  print(vim.inspect(state.goals))
end

-- Highlighting / Extmark Namespace
state.extmark_namespace = vim.api.nvim_create_namespace('Agda_Extmark')
state.highlight_namespace = vim.api.nvim_create_namespace('Agda_Hightlight')

state.pending = {}
state.status = enums.Status.EMPTY

return {
  test                    = test                            ,
  auto                    = actions.auto                    ,
  back                    = actions.back                    ,
  case                    = actions.case                    ,
  context                 = actions.context                 ,
  forward                 = actions.forward                 ,
  give                    = actions.give                    ,
  goal_type_context       = actions.goal_type_context       ,
  goal_type_context_infer = actions.goal_type_context_infer ,
  load                    = actions.load                    ,
  refine                  = actions.refine                  ,
  start                   = connection.start                ,
  stop                    = connection.stop                 ,
  version                 = actions.version                 ,
  window                  = output.initialize               ,
}
