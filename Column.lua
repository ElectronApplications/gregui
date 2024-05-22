local gui = require("gregui.gui")

---@class ColumnProps
---@field children Element[]
---@field horizontal_alignment "left" | "center" | "right"

---@param props ColumnProps
return function(props)
    setmetatable(props, {
        __index = {
            children = {},
            horizontal_alignment = "left"
        }
    })

    return gui.create_drawable_element(function(width, height, render_callback)
        local y = 1
        local h = 0
        for _, child in pairs(props.children) do
            render_callback(child, width, height - y + 1, function(child_width, child_height)
                h = child_height
                if props.horizontal_alignment == "left" then
                    return 1, y
                elseif props.horizontal_alignment == "center" then
                    return (width - child_width) // 2 + 1, y
                else
                    return width - child_width + 1, y
                end
            end)
            y = y + h
        end
        return width, y - 1
    end, -1, -1)
end
