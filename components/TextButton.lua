local gui = require("gregui.gui")
local Button = require("gregui.components.Button")
local Text = require("gregui.components.Text")

---@class TextButtonProps
---@field text string
---@field on_click function
---@field background integer
---@field foreground integer

---@param props TextButtonProps
---@return Element
return function(props)
    setmetatable(props, {
        __index = {
            background = 0xDFDFDF,
            foreground = 0x000000
        }
    })

    return gui.create_element(
        Button,
        {
            content = gui.create_element(
                Text,
                {
                    text = props.text
                }
            ),
            background = props.background,
            foreground = props.foreground,
            on_click = props.on_click
        }
    )
end