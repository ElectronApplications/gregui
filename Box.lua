local gui = require("gregui.gui")

---@class BoxProps
---@field element Element
---@field padding_left integer
---@field padding_right integer
---@field padding_top integer
---@field padding_bottom integer

---@param props BoxProps
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
  
    return gui.create_drawable_element(function(width, height, render_callback)
      local w = 0
      local h = 0
      render_callback(props.element, width - pl - pr, height - pt - pb, function(child_width, child_height)
        w = child_width
        h = child_height
        return pl + 1, pt + 1
      end)
      return w + pl + pr, h + pt + pb
    end, -1, -1)
  end