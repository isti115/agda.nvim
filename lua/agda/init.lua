--[[
  Agda interaction plugin for NeoVim written in Lua
  István Donkó (Isti115@GitHub)
  Copyright (C) 2021

  Terminology:
    + nvim:
      - top  : row number starting from zero
      - left : byte offset from the beginning of the line
      - byte : byte offset from the beginning of the file
    + Agda:
      - line : row number starting from one
      - col  : character offset from the beginning of the line
      - pos  : character offset from the beginning of the file

  Notes:
    * Agda uses `start` and `end` for the limits of ranges,
      but `end` is a reserved keyword in Lua...
--]]


local actions    = require('agda.actions')
local connection = require('agda.connection')
local output     = require('agda.output')
local state      = require('agda.state')

-- print('agda-mode loaded')

-- Highlighting Namespace
state.hl_ns = vim.api.nvim_create_namespace('Agda')

local function window ()
  output.initialize()
end

return {
  auto    = actions.auto,
  back    = actions.back,
  case    = actions.case,
  context = actions.context,
  forward = actions.forward,
  load    = actions.load,
  refine  = actions.refine,
  start   = connection.start,
  stop    = connection.stop,
  test    = connection.test,
  version = actions.version,
  window  = window,
}
