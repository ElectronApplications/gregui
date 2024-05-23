local math = require("math")

local component = require("component")
local event = require("event")
local gpu = component.gpu

local util = require("gregui.util")

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

---@alias coordinates_callback_function fun(width: integer, height: integer): (integer, integer)
---@alias render_callback_function fun(element: Element, max_width: integer, max_height: integer, coordinates_callback: coordinates_callback_function)
---@alias render_function fun(width: integer, height: integer, render_callback: render_callback_function): (integer, integer)

---@class DrawableElement
---@field type "drawable"
---@field element render_function
---@field max_width integer
---@field max_height integer
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

---@param render render_function
---@param max_width integer
---@param max_height integer
---@param events table<string, function>?
---@param key (string | number)?
---@return DrawableElement
function gui.create_drawable_element(render, max_width, max_height, events, key)
    return {
        type = "drawable",
        element = render,
        max_width = max_width,
        max_height = max_height,
        events = events,
        key = key
    }
end

---@param node Element
---@param max_width integer
---@param max_height integer
---@param coordinates_callback coordinates_callback_function
---@return { node_key: string, frame: { x: integer, y: integer, w: integer, h: integer } }
local function recursive_render(node, max_width, max_height, coordinates_callback)
    local node_key = global_parent .. "_" .. global_id
    if node.key ~= nil then
        node_key = node_key .. "_key_" .. node.key
    else
        global_id = global_id + 1
    end
    node_key = node_key .. "_" .. string.sub(tostring(node.element), 11)
    
    if node.events ~= nil then
        global_events[node_key] = node.events
    end

    local prev_parent = global_parent
    local prev_id = global_id

    global_parent = node_key
    global_id = 0

    global_context[node_key] = {
        pass_frame = true,
        local_frame = {},
        children = {}
    }

    if node.type == "composable" then
        local child_info = recursive_render(node.element(node.props), max_width, max_height, coordinates_callback)
        global_context[node_key].pass_frame = false
        global_context[node_key].local_frame = child_info.frame
        global_context[node_key].children = { child_info.node_key }
    else
        local width = (node.max_width < 0 and { max_width } or { math.min(node.max_width, max_width) })[1]
        local height = (node.max_height < 0 and { max_height } or { math.min(node.max_height, max_height) })[1]

        local current_buffer = gpu.getActiveBuffer()
        local buffer = gpu.allocateBuffer(width, height)
        gpu.setActiveBuffer(buffer)

        width, height = node.element(width, height, function(element, max_width, max_height, coordinates_callback)
            local child_info = recursive_render(element, max_width, max_height, coordinates_callback)
            table.insert(global_context[node_key].children, child_info.node_key)
        end)

        local x, y = coordinates_callback(width, height)
        gpu.bitblt(current_buffer, x, y, width, height, buffer, 1, 1)

        gpu.setActiveBuffer(current_buffer)
        gpu.freeBuffer(buffer)

        global_context[node_key].local_frame = {
            x = x,
            y = y,
            w = width,
            h = height
        }
    end

    global_parent = prev_parent
    global_id = prev_id
    return {
        node_key = node_key,
        frame = global_context[node_key].local_frame
    }
end

---@param node_key string
---@param frame { x: integer, y: integer, w: integer, h: integer }
local function recursive_calc_frame(node_key, frame)
    for _, child_key in pairs(global_context[node_key].children) do
        local child_frame = global_context[child_key].local_frame
        global_context[child_key].global_frame = {
            x = frame.x + child_frame.x - 1,
            y = frame.y + child_frame.y - 1,
            w = child_frame.w,
            h = child_frame.h
        }
        if global_context[child_key].pass_frame then
            recursive_calc_frame(child_key, global_context[child_key].global_frame)
        else
            recursive_calc_frame(child_key, frame)
        end
    end
end

---@param start_node fun(): Element
function gui.start(start_node)
    local status, err = pcall(function()
        local w, h = gpu.getResolution()

        global_id = 0
        global_parent = string.sub(tostring(start_node), 11)
        global_context = {}
        global_events = {}

        local child_info = recursive_render(start_node(), w, h, function(width, height)
            return 1, 1
        end)

        global_context[child_info.node_key].global_frame = child_info.frame
        recursive_calc_frame(child_info.node_key, child_info.frame)
    end)

    if not status then
        gpu.freeAllBuffers()
        print(err)
    end

    while true do
        local id, _, x, y = event.pullMultiple("touch", "interrupted")
        if id == "interrupted" then
            break
        elseif id == "touch" then
            for node_key, events_list in pairs(global_events) do
                for event, callback in pairs(events_list) do
                    if event == "on_click" then
                        local frame = global_context[node_key].global_frame
                        if x >= frame.x and x < frame.x  + frame.w and y >= frame.y and y < frame.y + frame.h then
                            callback()
                        end
                    end
                end
            end
        end
    end
end

return gui
