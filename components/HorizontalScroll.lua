local math = require("math")
local gui = require("gregui.gui")

---@class HorizontalScrollProps
---@field content Element

---@param props HorizontalScrollProps
---@return Element
return function(props)
    local scroll, set_scroll = gui.use_state(0)

    return gui.create_drawable_element{
        prepare = function(prepare_callback)
            return prepare_callback(props.content)
        end,
        draw = function(renderer, children)
            local new_scroll = math.max(renderer:get_screen_w() - renderer:get_w(), scroll)
            children[1].draw_callback(1 + new_scroll, 1)
        end,
        events = {
            on_scroll = function(player_name, direction, x, y, w, h, screen_w, screen_h)
                local new_scroll = math.max(screen_w - w, math.min(0, scroll + direction))
                set_scroll(new_scroll)
            end
        }
    }
end