local gui = require("gregui.gui")

---@class ButtonProps
---@field text string
---@field on_click function

---@param props ButtonProps
---@return Element
return function(props)
    local text_len = string.len(props.text)

    return gui.create_drawable_element(
        function (prepare_callback)
            return text_len + 2, 3
        end,
        function (renderer, children)
            renderer:set(1, 1, "+")
            renderer:set(1, 3, "+")
            renderer:set(text_len + 2, 1, "+")
            renderer:set(text_len + 2, 3, "+")
            
            renderer:fill(2, 1, text_len, 1, "-")
            renderer:fill(2, 3, text_len, 1, "-")
    
            renderer:set(1, 2, "|")
            renderer:set(text_len + 2, 2, "|")
            
            renderer:set(2, 2, props.text)
        end,
        {
            on_click = props.on_click
        }
    )
  end