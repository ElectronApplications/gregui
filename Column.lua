local math = require("math")
local gui = require("gregui.gui")

---@class ColumnProps
---@field children Element[]
---@field fill_max_width boolean
---@field horizontal_alignment "left" | "center" | "right"

---@param props ColumnProps
return function(props)
    setmetatable(props, {
        __index = {
            children = {},
            fill_max_width = true,
            horizontal_alignment = "left"
        }
    })

    return gui.create_drawable_element(function(width, height, render_callback)
        local w = 0
        local h = 0
        for _, child in pairs(props.children) do
            render_callback(child, width, height - h, function(child_width, child_height)
                local y = h + 1
                w = math.max(w, child_width)
                h = h + child_height
                if not props.fill_max_width then
                    return 1, y
                elseif props.horizontal_alignment == "left" then
                    return 1, y
                elseif props.horizontal_alignment == "center" then
                    return (width - child_width) // 2 + 1, y
                else
                    return width - child_width + 1, y
                end
            end)
        end
        
        if props.fill_max_width then
            return width, h
        else
            return w, h
        end
    end, -1, -1)
end
