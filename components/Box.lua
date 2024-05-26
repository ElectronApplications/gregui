local gui = require("gregui.gui")

---@class BoxProps
---@field content Element
---@field padding_left integer?
---@field padding_right integer?
---@field padding_top integer?
---@field padding_bottom integer?

---@param props BoxProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            padding_left = 0,
            padding_right = 0,
            padding_top = 0,
            padding_bottom = 0
        }
    })
  
    local pl = props.padding_left
    local pr = props.padding_right
    local pt = props.padding_top
    local pb = props.padding_bottom

    return gui.create_drawable_element(
        function (prepare_callback)
            local w, h = prepare_callback(props.content)
            
            local width = nil
            local height = nil
            
            if w ~= nil then
                width = pl + w + pr
            end

            if h ~= nil then
                height = pt + h + pb
            end

            return width, height
        end,
        function (renderer, children)
            children[1].draw_callback(pl + 1, pt + 1)
        end
    )
end