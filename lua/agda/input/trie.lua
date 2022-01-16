local list = require 'agda.utilities.list'

local trie_mt = {}
local trie = {}

function string:at(idx)
  return self:sub(idx, idx)
end

function string.iter(str)
  local i = 0
  local n = string.len(str)
  return function()
    i = i + 1
    if i <= n then return str:at(i) end
  end
end

function trie.new(inpt)
  local result = setmetatable({root = {}}, trie_mt)

  if inpt ~= nil then
    for k,v in pairs(inpt) do
      result:set_at(k, v)
    end
  end

  return result
end

function trie_mt:prefix(key)
  local node = self.root
  for c in key:iter() do
    if node.next == nil or node.next[c] == nil then
      node = nil
      break
    end

    node = node.next[c]
  end

  if node == nil then
    return nil, "key "..key.." does not exist"
  else
    return setmetatable({root = node}, trie_mt)
  end
end


function trie_mt:get_at(key)
  local result, err = self:prefix(key)
  if result == nil then
    return nil, err
  elseif result.root.val == nil then
    return nil, "key "..key.." does not contain a value"
  else
    return result.root.val
  end
end

function trie_mt:totable()
  local result = {}
  local queue = list.new { {prefix = '', node = self.root} }
  while queue:len() ~= 0 do
    local elem = queue:popleft()
    local prefix = elem.prefix
    local node = elem.node
    if node.val ~= nil then
      result[prefix] = node.val
    end

    if node.next ~= nil then
      for k, v in pairs(node.next) do
        queue:pushright { prefix = prefix..k, node = v }
      end
    end
  end
  return result
end

function trie_mt:set_at(key, val)
  local node = self.root
  for c in key:iter() do
    if node.next == nil then
      node.next = {}
    end

    if node.next[c] == nil then
      node.next[c] = {}
    end

    node = node.next[c]
  end

  node.val = val
end

function trie_mt.__index(tbl, key)
  if trie_mt[key] ~= nil then
    return trie_mt[key]
  else
    return tbl:get_at(key)
  end
end

function trie_mt.__newindex(tbl, key, value)
  if trie_mt[key] ~= nil then
    return nil, "cannot set trie method"
  else
    return tbl:set_at(key, value)
  end
end

return trie
