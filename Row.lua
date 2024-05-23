local math = require("math")
local gui = require("gregui.gui")

---@class RowProps
---@field children Element[]
---@field fill_max_height boolean
---@field vertical_alignment "top" | "center" | "bottom"

---@param props RowProps
return function(props)
    setmetatable(props, {
        __index = {
            children = {},
            fill_max_height = false,
            vertical_alignment = "top"
        }
    })

    return gui.create_drawable_element(function(width, height, render_callback)
        local w = 0
        local h = 0
        for _, child in pairs(props.children) do
            render_callback(child, width - w, height, function(child_width, child_height)
                local x = w + 1
                h = math.max(h, child_height)
                w = w + child_width
                if not props.fill_max_height then
                    return x, 1
                elseif props.vertical_alignment == "top" then
                    return x, 1
                elseif props.vertical_alignment == "center" then
                    return x, (height - child_height) // 2 + 1
                else
                    return x, height - child_height + 1
                end
            end)
        end
        
        if props.fill_max_height then
            return w, height
        else
            return w, h
        end
    end, -1, -1)
end
