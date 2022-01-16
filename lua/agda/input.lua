local symbol_from_file = require 'agda.input.file'

local function get_cursor(buf)
  return table.unpack(vim.api.nvim_win_get_cursor(buf))
end

local function setline_range(buf, line, start_col, end_col, text)
  vim.api.nvim_buf_set_text(buf, line-1, start_col, line-1, end_col, {text})
end

local input = {}

function input.new(symbols)
  local result = setmetatable({
    state = { started = false },
    symbols = symbols or {},
    namespace = vim.api.nvim_create_namespace('agda_input')
  }, {
    __index = input
  })

  result.edit_buf = result:init_buf()

  return result
end

function input.fromfile(fname)
  local symbols, err = symbol_from_file(fname)

  if err ~= nil then
    return nil, err
  end

  return input.new(symbols)
end

function input:clear_highlight()
  vim.api.nvim_buf_clear_namespace(0, self.namespace, 0, -1)
end

function input:update_highlight(width)
  self:clear_highlight()

  if self.state.extmark ~= nil then
    vim.api.nvim_buf_del_extmark(self.edit_buf, self.namespace, self.state.extmark)
  end

  if self.state.candidates ~= nil then
    vim.api.nvim_win_set_config(self.state.win, {
      width = width + 4
    })

    vim.api.nvim_buf_add_highlight(self.edit_buf, self.namespace, 'agda_input_matched', 0, 0, width)
    self.state.extmark = vim.api.nvim_buf_set_extmark(self.edit_buf, self.namespace, 0, 0, {
      virt_text = {{string.format('[%s]', self.state.candidates[self.state.choice])}},
      virt_text_pos = 'eol'
    })
  else
    vim.api.nvim_win_set_config(self.state.win, {
      width = width+1
    })
  end
end

function input:reset()
  if not self.state.started then
    return
  end
  if self.state.candidates ~= nil then
    local repl = self.state.candidates[self.state.choice]
    local start_line, start_col = table.unpack(self.state.start_pos)
    vim.api.nvim_win_set_cursor(self.state.orig_win, {start_line, start_col + vim.fn.len(repl)})
  end

  self:clear_highlight()
  vim.api.nvim_buf_set_lines(self.edit_buf, 0, -1, false, {})
  vim.api.nvim_win_close(self.state.win, true)

  self.state = { started = false }
end

function input:commit()
  if not self.state.started then
    return
  end

  local start_line, start_col = table.unpack(self.state.start_pos)

  if self.state.candidates ~= nil then
    local repl = self.state.candidates[self.state.choice]
    setline_range(self.state.orig_buf, start_line, start_col, start_col, repl)
  end

  self:reset()
end

function input:next_choice()
  if self.state.candidates ~= nil then
    self.state.choice = (self.state.choice % #self.state.candidates) + 1
    self:update_highlight(vim.fn.len(self.state.candidates[self.state.choice]))
  end
end

function input:prev_choice()
  if self.state.candidates ~= nil then
    self.state.choice = ((self.state.choice - 2) % #self.state.candidates) + 1
    self:update_highlight(vim.fn.len(self.state.candidates[self.state.choice]))
  end
end

local function t(str)
    -- Adjust boolean arguments as needed
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

function input:update()
  if not self.state.started then
    return
  end

  local text = vim.api.nvim_buf_get_lines(0, 0, 1, true)[1]

  self.state.candidates = self.symbols:get_at(text)

  if self.state.candidates ~= nil then
    self.state.choice = 1
  end

  self:update_highlight(vim.fn.len(text))

  if self.state.candidates ~= nil then
    vim.api.nvim_buf_set_keymap(0, 'i', '<Tab>', '', {
      callback = function()
        self:next_choice()
      end
    })

    vim.api.nvim_buf_set_keymap(0, 'i', '<S-Tab>', '', {
      callback = function()
        self:prev_choice()
      end
    })
  end
end

function input:start()
  if self.state.started then
    self:commit()
  end

  if self.edit_buf == nil or not vim.api.nvim_buf_is_valid(self.edit_buf) then
    self.edit_buf = self:init_buf()
  end

  local start_pos = {get_cursor(0)}

  local orig_buf = vim.api.nvim_get_current_buf()
  local orig_win = vim.api.nvim_get_current_win()
  local win = vim.api.nvim_open_win(self.edit_buf, true, {
    relative = "cursor",
    width = 1,
    height = 1,
    row = 0,
    col = 0,
    noautocmd = true,
    style = "minimal"
  })
  self.state = {
    started = true,
    start_pos = start_pos,
    win = win,
    orig_buf = orig_buf,
    orig_win = orig_win
  }
end

vim.cmd[[
hi def link agda_input_matched Underlined
]]

function input:init_buf()
  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_add_user_command(buf, "AgdaInputUpdate", function() self:update() end, {})
  vim.api.nvim_buf_add_user_command(buf, "AgdaInputCommit", function() self:commit() end, {})
  vim.api.nvim_buf_add_user_command(buf, "AgdaInputReset", function() self:reset() end, {})
  vim.api.nvim_buf_call(buf, function()
    vim.cmd[[
    augroup agda_input
    autocmd! * <buffer>
    autocmd TextChangedI <buffer> AgdaInputUpdate 
    autocmd TextChangedP <buffer> AgdaInputUpdate 
    " autocmd InsertLeave <buffer> AgdaInputCommit
    " autocmd BufLeave <buffer> AgdaInputCommit
    augroup END
    ]]
    vim.api.nvim_buf_set_keymap(buf, 'i', '<cr>', '<cmd>AgdaInputCommit<cr>', {
      noremap = true
    })
    vim.api.nvim_buf_set_keymap(buf, 'i', '<space>', '<cmd>AgdaInputCommit<cr><space>', {
      noremap = true
    })
    vim.api.nvim_buf_set_keymap(buf, 'i', '<esc>', '<cmd>AgdaInputReset<cr>', {
      noremap = true
    })
    vim.api.nvim_buf_set_keymap(buf, 'i', '<BS>', '', {
      callback = function()
        local _, col = get_cursor(0)
        if col == 0 then
          return t'<cmd>AgdaInputReset<cr>'
        else
          return t'<bs>'
        end
      end,
      expr = true,
      noremap = true
    })
  end)

  return buf
end

return input
