local util = require("gregui.util")

---@class EventHandlers
---@field on_click fun(player_name: string, button: integer, x: integer, y: integer, w: integer, h: integer, screen_w: integer, screen_h: integer)?
---@field on_scroll fun(player_name: string, direction: integer, x: integer, y: integer, w: integer, h: integer, screen_w: integer, screen_h: integer)?

---@class ContextElement
---@field rendered boolean
---@field states any[]
---@field cache { dependencies: any[]?, cleanup: function?, value: any? }[]
---@field element Element
---@field children string[]
---@field x integer
---@field y integer
---@field w integer?
---@field h integer?
---@field screen_x integer
---@field screen_y integer
---@field screen_w integer
---@field screen_h integer

---@class Context
---@field id integer
---@field parent string
---@field events table<string, EventHandlers>
---@field event_areas { node_key: string, event: string, x: integer, y: integer, w: integer, h: integer }[]
---@field private elements table<string, ContextElement>
---
---@field get_id_inc fun(self: Context): integer
---@field get_id_reset fun(self: Context): integer
---@field set_parent fun(self: Context, node_key: string): string
---@field element_present fun(self: Context, node_key: string): boolean
---@field obtain_element fun(self: Context, node_key: string): ContextElement
---@field set_not_rendered fun(self)
---@field remove_not_rendered fun(self)

---@return Context
return function()
    local Context = {
        id = 0,
        parent = "",
        elements = {},
        events = {},
        event_areas = {}
    }
    
    function Context.get_id_inc(self)
        local current_id = self.id
        self.id = self.id + 1
        return current_id
    end

    function Context.get_id_reset(self)
        local current_id = self.id
        self.id = 0
        return current_id
    end

    function Context.set_parent(self, node_key)
        local current_pattern = self.parent
        self.parent = node_key
        return current_pattern
    end

    function Context.element_present(self, node_key)
        return self.elements[node_key] ~= nil
    end

    function Context.obtain_element(self, node_key)
        local context_element = self.elements[node_key]
        if context_element == nil then
            context_element = {
                rendered = true,
                states = {},
                cache = {},
                element = {},
                children = {},
                x = 0,
                y = 0,
                w = 0,
                h = 0,
                screen_x = 0,
                screen_y = 0,
                screen_w = 0,
                screen_h = 0
            }
            self.elements[node_key] = context_element
        end

        return context_element
    end

    function Context.set_not_rendered(self)
        for _, element in pairs(self.elements) do
            element.rendered = false
        end
    end

    function Context.remove_not_rendered(self)
        self.elements = util.filter(self.elements, function(element)
            if not element.rendered then
                for _, cache in pairs(element.cache) do
                    if cache.cleanup ~= nil then
                        cache.cleanup()
                    end
                end
            end

            return element.rendered
        end)
    end

    return Context
end