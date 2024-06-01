local util = require("gregui.util")

local element = {}

---@class ComposableElement
---@field type "composable"
---@field element fun(props: any): Element | "nil"
---@field props any
---@field events EventHandlers?
---@field key (string | number)?
---@field props_equal (fun(prev_props: any, new_props: any): boolean)?
---@field disable_memo boolean?

---@alias prepare_callback_function fun(element: Element): (integer | nil, integer | nil)
---@alias prepare_function fun(prepare_callback: prepare_callback_function): (integer | nil, integer | nil)

---@alias draw_function fun(renderer: Renderer, children: { w: integer, h: integer, draw_callback: fun(x: integer, y: integer, w: integer?, h: integer?) }[])

---@class DrawableElement
---@field type "drawable"
---@field prepare prepare_function
---@field draw draw_function
---@field events EventHandlers?
---@field key (string | number)?

---@alias Element ComposableElement | DrawableElement

---@param prev_props any
---@param new_props any
---@param props_equal function
---@return boolean
function element.compare_props(prev_props, new_props, props_equal)
    if props_equal ~= nil then
        return props_equal(prev_props, new_props)
    else
        if type(prev_props) == "table" and type(new_props) == "table" then
            return util.all(new_props, function(value, key)
                return prev_props[key] == value
            end)
        else
            return prev_props == new_props
        end
    end
end

---@param element_table Element
local function element_metatable(element_table)
    setmetatable(element_table, {
        __eq = function(t1, t2)
            if type(t1) == "table" and type(t2) == "table" then
                if t1.type == "composable" and t2.type == "composable" then
                    return t1.element == t2.element and t1.key == t2.key and element.compare_props(t1.props, t2.props, t1.props_equal)
                elseif t1.type == "drawable" and t2.type == "drawable" then
                    return t1.prepare == t2.prepare and t1.draw == t2.draw and t1.key == t2.key
                else
                    return false
                end
            else
                return false
            end
        end
    })
end

---@generic T
---@param parameters { element: (fun(props: T): Element | "nil"), props: T, events: EventHandlers?, key: (string | number)?, props_equal: (fun(prev_props: T, new_props: T): boolean)?, disable_memo: boolean? }
---@return ComposableElement
function element.create_element(parameters)
    local element = {
        type = "composable",
        element = parameters.element,
        props = parameters.props,
        events = parameters.events,
        key = parameters.key,
        props_equal = parameters.props_equal,
        disable_memo = parameters.disable_memo
    }

    element_metatable(element)

    return element
end

---@param parameters { prepare: prepare_function, draw: draw_function, events: EventHandlers?, key: (string | number)? }
---@return DrawableElement
function element.create_drawable_element(parameters)
    local element = {
        type = "drawable",
        prepare = parameters.prepare,
        draw = parameters.draw,
        events = parameters.events,
        key = parameters.key
    }

    element_metatable(element)


    return element
end

---@alias ElementsArray (Element | "nil")[]

---@param elements (Element | "nil")[]
---@return ElementsArray
function element.elements_array(elements)
    setmetatable(elements, {
        __eq = function(t1, t2)
            if type(t1) == "table" and type(t2) == "table" then
                if #t1 == #t2 then
                    return util.all(t1, function(value, key)
                        return value == t2[key]
                    end)
                else
                    return false
                end
            else
                return false
            end
        end
    })
    
    return elements
end

return element