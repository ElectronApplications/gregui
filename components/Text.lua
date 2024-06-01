local gui = require("gregui.gui")

---@class TextProps
---@field text string
---@field color integer?
---@field vertical boolean?

-- TODO: multiline text

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

    return gui.create_drawable_element{
        prepare = function (prepare_callback)
            return width, height
        end,
        draw = function (renderer, children)
            if props.color ~= nil then
                renderer.set_foreground(props.color)
            end
            renderer:set(1, 1, props.text, props.vertical)
        end
    }
end