local math = require("math")

local event = require("event")
local component = require("component")
local gpu = component.gpu

local util = require("gregui.util")
local Renderer = require("gregui.renderer")

local gui = {}

---@type integer
local global_id = 0

---@type string
local global_parent = ""

local global_context = {}
local global_events = {}

---@class ComposableElement
---@field type "composable"
---@field element fun(props: table): Element
---@field props table
---@field events table<string, function>?
---@field key (string | number)?

---@alias prepare_callback_function fun(element: Element): (integer | nil, integer | nil)
---@alias prepare_function fun(prepare_callback: prepare_callback_function): (integer | nil, integer | nil)

---@alias draw_function fun(renderer: Renderer, children: { w: integer, h: integer, draw_callback: fun(x: integer, y: integer, w: integer?, h: integer?) }[])

---@class DrawableElement
---@field type "drawable"
---@field prepare prepare_function
---@field draw draw_function
---@field events table<string, function>?
---@field key (string | number)?

---@alias Element ComposableElement | DrawableElement


---@param element fun(props: table): Element
---@param props table
---@param events table<string, function>?
---@param key (string | number)?
---@return ComposableElement
function gui.create_element(element, props, events, key)
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
---@param events table<string, function>?
---@param key (string | number)?
---@return DrawableElement
function gui.create_drawable_element(prepare, draw, events, key)
    return {
        type = "drawable",
        prepare = prepare,
        draw = draw,
        events = events,
        key = key
    }
end

---@param node Element
---@return { node_key: string, w: integer, h: integer }
local function recursive_build(node)
    local node_key = global_parent .. "_" .. global_id
    
    if node.key ~= nil then
        node_key = node_key .. "_key_" .. node.key
    else
        global_id = global_id + 1
    end

    if node.type == "composable" then
        node_key = node_key .. "_" .. util.func_tostring(node.element)
    end
    
    if node.events ~= nil then
        global_events[node_key] = node.events
    end

    local prev_parent = global_parent
    local prev_id = global_id

    global_parent = node_key
    global_id = 0

    if global_context[node_key] == nil then
        global_context[node_key] = {
            rendered = true,
            states = {},
            children = {},
            element = node
        }
    else
        global_context[node_key].rendered = true
        global_context[node_key].children = {}
        global_context[node_key].element = node
    end

    if node.type == "composable" then
        local child_info = recursive_build(node.element(node.props))
        global_context[node_key].width = child_info.w
        global_context[node_key].height = child_info.h
        global_context[node_key].children = { child_info.node_key }
    else
        local width, height = node.prepare(function(element)
            local child_info = recursive_build(element)
            table.insert(global_context[node_key].children, child_info.node_key)
            return child_info.w, child_info.h
        end)

        global_context[node_key].width = width
        global_context[node_key].height = height
    end

    global_parent = prev_parent
    global_id = prev_id
    return {
        node_key = node_key,
        w = global_context[node_key].width,
        h = global_context[node_key].height
    }
end

---@param node_key string
---@param current_width integer
---@param current_height integer
local function recursive_recalc_frames(node_key, current_width, current_height)
    global_context[node_key].width = global_context[node_key].width or current_width
    global_context[node_key].height = global_context[node_key].height or current_height

    for _, child_key in pairs(global_context[node_key].children) do
        recursive_recalc_frames(child_key, global_context[node_key].width, global_context[node_key].height)
    end
end

---@param node_key string
---@param x integer
---@param y integer
---@param w integer
---@param h integer
local function recursive_render(node_key, x, y, w, h)
    global_context[node_key].x = x
    global_context[node_key].y = y
    
    ---@type Element
    local element = global_context[node_key].element

    if element.type == "composable" then
        recursive_render(global_context[node_key].children[1], x, y, w, h)
    else
        element.draw(Renderer(x, y, w, h), util.map(global_context[node_key].children, function(child_key)
            return {
                w = global_context[child_key].width,
                h = global_context[child_key].height,
                draw_callback = function(child_x, child_y, child_w, child_h)
                    local old_background, old_foreground = gpu.getBackground(), gpu.getForeground()
                    
                    local width = global_context[child_key].width
                    local height = global_context[child_key].height

                    if child_w ~= nil then
                        width = math.min(width, child_w)
                    end

                    if child_h ~= nil then
                        height = math.min(height, child_h)
                    end

                    recursive_render(child_key, x + child_x - 1, y + child_y - 1, width, height)

                    gpu.setBackground(old_background)
                    gpu.setForeground(old_foreground)
                end
            }
        end))
    end
end

---@type fun(): Element
local global_component

local function internal_render()
    local status, err = pcall(function()
        local node_key = util.func_tostring(global_component)
        global_id = 0
        global_parent = node_key
        global_events = {}

        for _, context in pairs(global_context) do
            context.rendered = false
        end

        local child_info = recursive_build(global_component())

        local w, h = gpu.getViewport()

        local states = {}
        if global_context[node_key] ~= nil then
            states = global_context[node_key].states
        end

        global_context[node_key] = {
            rendered = true,
            states = states,
            width = w,
            height = h,
            children = { child_info.node_key },
            element = {
                type = "composable"
            }
        }

        global_context = util.filter(global_context, function(context)
            return context.rendered
        end)

        recursive_recalc_frames(node_key, w, h)

        gpu.fill(1, 1, w, h, " ")

        recursive_render(node_key, 1, 1, w, h)
    end)

    if not status then
        gpu.freeAllBuffers()
        print(err)
    end
end

---@param start_node fun(): Element
function gui.start(start_node)
    global_context = {}

    global_component = start_node
    internal_render()

    while true do
        local id, _, x, y = event.pullMultiple("touch", "interrupted")
        if id == "interrupted" then
            break
        elseif id == "touch" then
            for node_key, events_list in pairs(global_events) do
                for event, callback in pairs(events_list) do
                    if event == "on_click" then
                        local node_x, node_y, node_w, node_h = global_context[node_key].x, global_context[node_key].y, global_context[node_key].width, global_context[node_key].height
                        if x >= node_x and x < node_x + node_w and y >= node_y and y < node_y + node_h then
                            callback()
                            goto outer_break -- break out of the outer loop
                        end
                    end
                end
            end
            ::outer_break::
        end
    end
end

---@generic T
---@param initial_state T
---@return T, fun(T)
function gui.use_state(initial_state)
    local parent = global_parent
    local id = global_id

    global_id = global_id + 1

    local current_context = global_context[parent]
    if current_context == nil then
        current_context = {
            rendered = true,
            states = {}
        }
        global_context[parent] = current_context
    end

    local current_state = current_context.states[id]
    if current_state == nil then
        current_state = initial_state
        current_context.states[id] = current_state
    end

    local set_state = function (new_value)
        current_context.states[id] = new_value
        internal_render()
    end

    return current_state, set_state
end

return gui
