local gui = require("gregui.gui")

---@class BoxProps
---@field content Element?
---@field padding_left integer?
---@field padding_right integer?
---@field padding_top integer?
---@field padding_bottom integer?
---@field fill_max_width boolean?
---@field fill_max_height boolean?
---@field width integer?
---@field height integer?

---@param props BoxProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            padding_left = 0,
            padding_right = 0,
            padding_top = 0,
            padding_bottom = 0,
            fill_max_width = false,
            fill_max_height = false
        }
    })
  
    local pl = props.padding_left
    local pr = props.padding_right
    local pt = props.padding_top
    local pb = props.padding_bottom

    return gui.create_drawable_element{
        prepare = function (prepare_callback)
            local width = nil
            local height = nil
            
            if props.content ~= nil then
                local w, h = prepare_callback(props.content)
                
                if w ~= nil then
                    width = pl + w + pr
                end
    
                if h ~= nil then
                    height = pt + h + pb
                end
            else
                width = pl + pr
                height = pt + pb
            end

            if props.width ~= nil then
                width = props.width
            end

            if props.height ~= nil then
                height = props.height
            end

            if props.fill_max_width then
                width = nil
            end

            if props.fill_max_height then
                height = nil
            end
            
            return width, height
        end,
        draw = function (renderer, children)
            if children[1] ~= nil then
                children[1].draw_callback(pl + 1, pt + 1)
            end
        end
    }
end