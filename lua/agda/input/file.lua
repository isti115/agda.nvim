local trie = require 'agda.input.trie'

local function from_file(fname)
  local status, result = pcall(vim.fn.readfile, fname)
  if status then
    local abbreviations = vim.fn.json_decode(result)

    return trie.new(abbreviations)
  else
    return nil, result
  end

end

return from_file
