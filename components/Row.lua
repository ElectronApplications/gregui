local math = require("math")
local gui = require("gregui.gui")
local util = require("gregui.util")

---@class RowProps
---@field children Element[]
---@field fill_max_height boolean
---@field vertical_alignment "top" | "center" | "bottom"

---@param props RowProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            children = {},
            fill_max_height = false,
            vertical_alignment = "top"
        }
    })

    return gui.create_drawable_element(
        function (prepare_callback)
            ---@type integer?
            local width = 0
            local height = nil

            if not props.fill_max_height then
                height = 0
            end

            for _, child in pairs(props.children) do
                local w, h = prepare_callback(child)
                
                if height ~= nil then
                    height = math.max(height, h)
                end

                if w == nil then
                    width = nil
                end

                if width ~= nil then
                    width = width + w
                end
            end

            return width, height
        end,
        function (renderer, children)
            local total_height = renderer:get_h()
            local x = 1

            for _, child in pairs(children) do
                if props.vertical_alignment == "top" then
                    child.draw_callback(x, 1)
                elseif props.vertical_alignment == "center" then
                    child.draw_callback(x, (total_height - child.h) // 2 + 1)
                else
                    child.draw_callback(x, total_height - child.h + 1)
                end

                x = x + child.w
            end
        end
    )
end
