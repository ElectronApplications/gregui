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

return util