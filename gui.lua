local math = require("math")

local event = require("event")
local component = require("component")
local gpu = component.gpu

local util = require("gregui.util")
local element = require("gregui.element")
local Renderer = require("gregui.renderer")
local Context = require("gregui.context")

local gui = {}

gui.create_element = element.create_element
gui.create_drawable_element = element.create_drawable_element

---@type Context
local context

---@param node Element
---@return { node_key: string, w: integer, h: integer }
local function recursive_build(node)
    local node_key = context.parent .. "_" .. context.id
    
    if node.key ~= nil then
        node_key = node_key .. "_key_" .. node.key
    else
        context.id = context.id + 1
    end

    if node.type == "composable" then
        node_key = node_key .. "_" .. util.func_tostring(node.element)
    end
    
    if node.events ~= nil then
        context.events[node_key] = node.events
    end

    local prev_parent = context:set_parent(node_key)
    local prev_id = context:get_id_reset()

    local current_context = context:obtain_element(node_key)
    current_context.rendered = true
    current_context.children = {}
    current_context.element = node

    if node.type == "composable" then
        local child_info = recursive_build(node.element(node.props))
        current_context.w = child_info.w
        current_context.h = child_info.h
        current_context.children = { child_info.node_key }
    else
        local width, height = node.prepare(function(element)
            local child_info = recursive_build(element)
            table.insert(current_context.children, child_info.node_key)
            return child_info.w, child_info.h
        end)

        current_context.w = width
        current_context.h = height
    end

    context.parent = prev_parent
    context.id = prev_id
    return {
        node_key = node_key,
        w = current_context.w,
        h = current_context.h
    }
end

---@param node_key string
---@param current_width integer
---@param current_height integer
local function recursive_recalc_frames(node_key, current_width, current_height)
    local current_context = context:obtain_element(node_key)
    current_context.w = current_context.w or current_width
    current_context.h = current_context.h or current_height

    for _, child_key in pairs(current_context.children) do
        recursive_recalc_frames(child_key, current_context.w, current_context.h)
    end
end

---@param node_key string
---@param x integer
---@param y integer
---@param w integer
---@param h integer
local function recursive_render(node_key, x, y, w, h)
    local current_context = context:obtain_element(node_key)
    current_context.x = x
    current_context.y = y

    ---@type Element
    local element = current_context.element

    if element.type == "composable" then
        recursive_render(current_context.children[1], current_context.x, current_context.y, current_context.w, current_context.h)
    else
        element.draw(Renderer(x, y, w, h), util.map(current_context.children, function(child_key)
            local child_context = context:obtain_element(child_key)
            return {
                w = child_context.w,
                h = child_context.h,
                draw_callback = function(child_x, child_y, child_w, child_h)
                    local old_background, old_foreground = gpu.getBackground(), gpu.getForeground()
                    
                    ---@type integer
                    local width = current_context.w
                    ---@type integer
                    local height = current_context.h

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
        context.id = 0
        context.parent = ""
        context.events = {}
        context:set_not_rendered()
        
        local parent_element = gui.create_element(global_component, {})
        local parent_info = recursive_build(parent_element)
        local parent_key = parent_info.node_key
        local parent_context = context:obtain_element(parent_key)
        
        local w, h = gpu.getViewport()
        parent_context.w = w
        parent_context.h = h
        
        context:remove_not_rendered()

        recursive_recalc_frames(parent_context.children[1], w, h)
        
        gpu.fill(1, 1, w, h, " ")
        recursive_render(parent_context.children[1], 1, 1, w, h)
    end)

    if not status then
        print(err)
    end
end

---@param start_node fun(): Element
function gui.start(start_node)
    context = Context()

    global_component = start_node
    internal_render()

    while true do
        local id, _, x, y = event.pullMultiple("touch", "interrupted")
        if id == "interrupted" then
            break
        elseif id == "touch" then
            for node_key, events_list in pairs(context.events) do
                if context:element_present(node_key) then
                    local element = context:obtain_element(node_key)
                    for event, callback in pairs(events_list) do
                        if event == "on_click" then
                            -- TODO: component overlaps
                            if x >= element.x and x < element.x + element.w and y >= element.y and y < element.y + element.h then
                                callback()
                                goto outer_break -- break out of the outer loop
                            end
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
    local parent = context.parent
    local id = context:get_id_inc()
    local current_context = context:obtain_element(parent)

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
