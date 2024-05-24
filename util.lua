local util = {}

---@generic T, E, U
---@param table table<T, E>
---@param f fun(E): U
---@return table<T, U>
function util.map(table, f)
  local result = {}
  for k, v in pairs(table) do
    result[k] = f(v)
  end
  return result
end

---@generic T, E
---@param table table<T, E>
---@param f fun(E): boolean
---@return table<T, E>
function util.filter(table, f)
  local result = {}
  for k, v in pairs(table) do
    if f(v) then
      result[k] = v
    end
  end
  return result
end

---@param func function
---@return string
function util.func_tostring(func)
  return string.sub(tostring(func), 11)
end

return util