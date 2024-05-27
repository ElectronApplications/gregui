local element = {}

---@class ComposableElement
---@field type "composable"
---@field element fun(props: any): Element | "nil"
---@field props any
---@field events EventHandlers?
---@field key (string | number)?

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

---@generic T
---@param element fun(props: T): Element | "nil"
---@param props T
---@param events EventHandlers?
---@param key (string | number)?
---@return ComposableElement
function element.create_element(element, props, events, key)
    return {
        type = "composable",
        element = element,
        props = props,
        events = events,
        key = key
    }
end

---@param prepare prepare_function
---@param draw draw_function
---@param events EventHandlers?
---@param key (string | number)?
---@return DrawableElement
function element.create_drawable_element(prepare, draw, events, key)
    return {
        type = "drawable",
        prepare = prepare,
        draw = draw,
        events = events,
        key = key
    }
end

return element