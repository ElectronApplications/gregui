local event = require("event")

local gui = require("gregui.gui")
local Surface = require("gregui.components.Surface")
local Box = require("gregui.components.Box")

---@class ButtonProps
---@field content Element
---@field on_click fun(player_name: string)
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

    local pressed, set_pressed = gui.use_state({false})

    gui.use_effect(function ()
        if pressed[1] then
            local event_id = event.timer(1, function()
                set_pressed({false})
            end)
    
            return function ()
                event.cancel(event_id)
            end
        end
    end, {pressed})

    return gui.create_element(
        Box,
        {
            content = gui.create_element(
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
                    elevation = (pressed[1] and {0} or {1})[1]
                }
            ),
            padding_left = (pressed[1] and {1} or {0})[1],
            padding_top = (pressed[1] and {1} or {0})[1]
        },
        {
            on_click = function(player_name)
                set_pressed({true})
                props.on_click(player_name)
            end
        }
    )
end