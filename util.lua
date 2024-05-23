local util = {}

---@param table table
---@param key any
---@return boolean
function util.contains(table, key)
    for k, _ in pairs(table) do
        if k == key then
            return true
        end
    end
    return false
end

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

return util