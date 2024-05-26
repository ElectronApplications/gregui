local gui = require("gregui.gui")

---@class SurfaceProps
---@field content Element
---@field background integer?
---@field foreground integer?
---@field elevation integer?
---@field fill_max_size boolean?

---@param props SurfaceProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            background = 0xFFFFFF,
            foreground = 0x000000,
            elevation = 0,
            fill_max_size = false
        }
    })

    return gui.create_drawable_element(
        function (prepare_callback)
            local w, h = prepare_callback(props.content)

            if props.fill_max_size then
                return nil, nil
            else
                return w + props.elevation, h + props.elevation
            end
        end,
        function (renderer, children)
            if props.elevation > 0 then
                local r, g, b = props.background >> 16 & 0xFF, props.background >> 8 & 0xFF, props.background & 0xFF
                r, g, b = math.ceil(r * 0.5), math.ceil(g * 0.5), math.ceil(b * 0.5)
                local darker_background = (r << 16) | (g << 8) | b
                
                renderer.set_background(darker_background)
                renderer:fill(renderer:get_w() - props.elevation + 1, 1 + props.elevation, props.elevation, renderer:get_h() - props.elevation, " ")
                renderer:fill(1 + props.elevation, renderer:get_h() - props.elevation + 1, renderer:get_w() - props.elevation, props.elevation, " ")
            end

            renderer.set_background(props.background)
            renderer.set_foreground(props.foreground)

            renderer:fill(1, 1, renderer:get_w() - props.elevation, renderer:get_h() - props.elevation, " ")

            children[1].draw_callback(1, 1)
        end
    )
end