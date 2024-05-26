local util = require("gregui.util")

---@class ContextElement
---@field rendered boolean
---@field states any[]
---@field element Element
---@field children string[]
---@field x integer
---@field y integer
---@field w integer?
---@field h integer?

---@class Context
---@field id integer
---@field parent string
---@field events table<string, table<string, function>>
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
        events = {}
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
                element = {},
                children = {},
                x = 0,
                y = 0,
                w = 0,
                h = 0
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
            return element.rendered
        end)
    end

    return Context
end