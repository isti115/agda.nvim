local List = {}
function List.new(init)
  return setmetatable({first = 1, last = #init, data = init}, {
    __index = function(self, k)
      if getmetatable(k) == getmetatable(0) then
        return self:at(k)
      else
        return List[k]
      end
    end,
    __tostring = List.tostring
  })
end

function List.pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list.data[first] = value
end

function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list.data[last] = value
end

function List.popleft (list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list.data[first]
  list.data[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end

function List.popright (list)
  local last = list.last
  if list.first > last then error("list is empty") end
  local value = list.data[last]
  list.data[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end

function List.iter_forward(list)
  local k = list.first-1
  return function()
    k = k + 1
    if k <= list.last then return 1+k-list.first,list.data[k] end
  end
end

function List.iter_backward(list)
  local k = list.last+1
  return function()
    k = k - 1
    if list.first <= k then return list.last-k,list.data[k] end
  end
end

function List.tostring(list)
  local str = '['
  local sep = ''
  for _,v in list:iter_forward() do
    str = str .. sep .. v
    sep = ','
  end
  str = str .. ']'
  return str
end

function List.at(list, idx)
  if 1 <= idx and idx <= list.last - list.first + 1 then
    return list.data[idx + list.first - 1]
  end
end

function List.len(list)
  return list.last - list.first + 1
end


return List
