local gui = require("gregui.gui")

---@class AnimatedVisibilityProps
---@field content Element
---@field visible boolean

---@param props AnimatedVisibilityProps
---@return Element
return function(props)
    local progress_visible = gui.animate_state({props.visible})

    return gui.create_drawable_element(
        function (prepare_callback)
            local w, h = prepare_callback(props.content)
            if props.visible then
                return w, (h == nil and {nil} or {math.floor(h * progress_visible)})[1]
            else
                return w, (h == nil and {nil} or {math.floor(h * (1 - progress_visible))})[1]
            end
        end,
        function (renderer, children)
            if props.visible then
                children[1].draw_callback(1, 1, children[1].w, math.floor(children[1].h * progress_visible))
            else
                children[1].draw_callback(1, 1, children[1].w, math.floor(children[1].h * (1 - progress_visible)))
            end
        end
    )
end