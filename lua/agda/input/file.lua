local cm = require 'plenary.context_manager'
local trie = require 'agda.input.trie'

local function from_file(fname)
  local file, err = io.open(fname, 'r')
  if err ~= nil then
    return nil, err
  end

  local result = trie.new()

  for line in file:lines() do
    local cur = {tail = {}}
    local head = true
    for word in line:gmatch('%S+') do
      if head then
        cur.head = word
        head = false
      else
        table.insert(cur.tail, word)
      end

      result[cur.head] = cur.tail
    end
  end

  return result
end

return from_file
