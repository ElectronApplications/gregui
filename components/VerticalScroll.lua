local math = require("math")
local gui = require("gregui.gui")

---@class VerticalScrollProps
---@field content Element

---@param props VerticalScrollProps
---@return Element
return function(props)
    local scroll, set_scroll = gui.use_state(0)

    return gui.create_drawable_element{
        prepare = function(prepare_callback)
            return prepare_callback(props.content)
        end,
        draw = function(renderer, children)
            local new_scroll = math.max(renderer:get_screen_h() - renderer:get_h(), scroll)
            children[1].draw_callback(1, 1 + new_scroll)
        end,
        events = {
            on_scroll = function(player_name, direction, x, y, w, h, screen_w, screen_h)
                local new_scroll = math.max(screen_h - h, math.min(0, scroll + direction))
                set_scroll(new_scroll)
            end
        }
    }
end