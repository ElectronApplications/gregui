local math = require("math")
local gui = require("gregui.gui")
local util = require("gregui.util")

---@class ColumnProps
---@field children Element[]
---@field fill_max_width boolean
---@field horizontal_alignment "left" | "center" | "right"

---@param props ColumnProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            children = {},
            fill_max_width = false,
            horizontal_alignment = "left"
        }
    })

    return gui.create_drawable_element(
        function (prepare_callback)
            local width = nil
            ---@type integer?
            local height = 0

            if not props.fill_max_width then
                width = 0
            end

            for _, child in pairs(props.children) do
                local w, h = prepare_callback(child)
                
                if width ~= nil then
                    width = math.max(width, w)
                end
                
                if h == nil then
                    height = nil
                end

                if height ~= nil then
                    height = height + h
                end
            end

            return width, height
        end,
        function (renderer, children)
            local total_width = renderer:get_w()
            local y = 1

            for _, child in pairs(children) do
                if props.horizontal_alignment == "left" then
                    child.draw_callback(1, y)
                elseif props.horizontal_alignment == "center" then
                    child.draw_callback((total_width - child.w) // 2 + 1, y)
                else
                    child.draw_callback(total_width - child.w + 1, y)
                end

                y = y + child.h
            end
        end
    )
end
