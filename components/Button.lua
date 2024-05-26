local gui = require("gregui.gui")
local Surface = require("gregui.components.Surface")
local Box = require("gregui.components.Box")

---@class ButtonProps
---@field content Element
---@field on_click function
---@field background integer?
---@field foreground integer?

---@param props ButtonProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            background = 0xDFDFDF,
            foreground = 0x000000
        }
    })

    return gui.create_element(
        Surface,
        {
            content = gui.create_element(
                Box,
                {
                    content = props.content,
                    padding_left = 1,
                    padding_right = 1,
                    padding_top = 1,
                    padding_bottom = 1
                }
            ),
            background = props.background,
            foreground = props.foreground,
            elevation = 1
        },
        {
            on_click = props.on_click
        }
    )
end