local math = require("math")
local gui = require("gregui.gui")

---@class TextProps
---@field text string
---@field vertical boolean?

---@param props TextProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            vertical = false
        }
    })

    local width = 1
    local height = 1

    if props.vertical then
        height = string.len(props.text)
    else
        width = string.len(props.text)
    end

    return gui.create_drawable_element(
        function (prepare_callback)
            return width, height
        end,
        function (renderer, children)
            renderer:set(1, 1, props.text, props.vertical)
        end
    )
end