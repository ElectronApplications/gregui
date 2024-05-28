local util = {}

---@generic T, E, U
---@param table table<T, E>
---@param f fun(value: E, key: T): U
---@return table<T, U>
function util.map(table, f)
    local result = {}
    for k, v in pairs(table) do
        result[k] = f(v, k)
    end
    return result
end

---@generic T, E
---@param table table<T, E>
---@param f fun(value: E, key: T): boolean
---@return table<T, E>
function util.filter(table, f)
    local result = {}
    for k, v in pairs(table) do
        if f(v, k) then
            result[k] = v
        end
    end
    return result
end

---@generic T, E
---@param array T[]
---@param f fun(value: E, key: T): boolean
---@return T[]
function util.array_filter(array, f)
    local result = {}
    for k, v in pairs(array) do
        if f(v, k) then
            table.insert(result, v)
        end
    end
    return result
end

---@generic T, E
---@param table table<T, E>
---@param f fun(value: E, key: T): boolean
---@return boolean
function util.any(table, f)
    for k, v in pairs(table) do
        if f(v, k) then
            return true
        end
    end
    return false
end

---@generic T, E
---@param table table<T, E>
---@param f fun(value: E, key: T): boolean
---@return boolean
function util.all(table, f)
    for k, v in pairs(table) do
        if not f(v, k) then
            return false
        end
    end
    return true
end

---@param func function
---@return string
function util.func_tostring(func)
    return string.sub(tostring(func), 11)
end

return util