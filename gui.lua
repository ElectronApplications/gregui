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

---@param node Element | "nil"
---@return { node_key: string, w: integer, h: integer }?
local function recursive_build(node)
    if node == "nil" then
        context.id = context.id + 1
        return nil
    end
    
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
    current_context.element = node --[[@as Element]]

    if node.type == "composable" then
        local child_info = recursive_build(node.element(node.props) --[[@as Element]])
        if child_info ~= nil then
            current_context.w = child_info.w
            current_context.h = child_info.h
            current_context.children = { child_info.node_key }
        end
    else
        local width, height = node.prepare(function(element)
            local child_info = recursive_build(element)
            if child_info ~= nil then
                table.insert(current_context.children, child_info.node_key)
                return child_info.w, child_info.h
            else
                return 0, 0
            end
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
---@param screen_x integer
---@param screen_y integer
---@param screen_w integer
---@param screen_h integer
local function recursive_draw(node_key, x, y, w, h, screen_x, screen_y, screen_w, screen_h)
    local current_context = context:obtain_element(node_key)
    current_context.x = x
    current_context.y = y
    current_context.screen_x = screen_x
    current_context.screen_y = screen_y
    current_context.screen_w = screen_w
    current_context.screen_h = screen_h

    if context.events[node_key] ~= nil then
        if context.events[node_key].on_click ~= nil then
            table.insert(context.event_areas, { node_key = node_key, event = "on_click", x = screen_x, y = screen_y, w = screen_w, h = screen_h })
        end
        if context.events[node_key].on_scroll ~= nil then
            table.insert(context.event_areas, { node_key = node_key, event = "on_scroll", x = screen_x, y = screen_y, w = screen_w, h = screen_h })
        end
    end

    ---@type Element
    local element = current_context.element

    if element.type == "composable" then
        if current_context.children[1] ~= nil then
            recursive_draw(current_context.children[1], x, y, w, h, screen_x, screen_y, screen_w, screen_h)
        end
    else
        element.draw(Renderer(x, y, w, h, screen_x, screen_y, screen_w, screen_h), util.map(current_context.children, function(child_key)
            local child_context = context:obtain_element(child_key)
            return {
                w = child_context.w,
                h = child_context.h,
                draw_callback = function(child_x, child_y, child_w, child_h)
                    local old_background, old_foreground = gpu.getBackground(), gpu.getForeground()
                    
                    local renderer_x = math.min(screen_x + screen_w - 1, math.max(screen_x, x + child_x - 1))
                    local renderer_y = math.min(screen_y + screen_h - 1, math.max(screen_y, y + child_y - 1))

                    local renderer_w = math.min(screen_w + screen_x - renderer_x, screen_w)
                    local renderer_h = math.min(screen_h + screen_y - renderer_y, screen_h)

                    renderer_w = math.min(renderer_w, x + child_x - 1 + child_context.w - renderer_x)
                    renderer_h = math.min(renderer_h, y + child_y - 1 + child_context.h - renderer_y)

                    if child_w ~= nil then
                        renderer_w = math.min(renderer_w, x + child_x - 1 + child_w - renderer_x)
                    end

                    if child_h ~= nil then
                        renderer_h = math.min(renderer_h, y + child_y - 1 + child_h - renderer_y)
                    end

                    recursive_draw(child_key, x + child_x - 1, y + child_y - 1, child_context.w, child_context.h, renderer_x, renderer_y, renderer_w, renderer_h)

                    gpu.setBackground(old_background)
                    gpu.setForeground(old_foreground)
                end
            }
        end))
    end
end

---@type fun(): Element | "nil"
local global_component

local function render()
    local status, err = pcall(function()
        context.id = 0
        context.parent = ""
        context.events = {}
        context.event_areas = {}
        context:set_not_rendered()
        
        local parent_element = gui.create_element(global_component, {})
        local parent_info = recursive_build(parent_element)

        if parent_info ~= nil then
            local parent_key = parent_info.node_key
            local parent_context = context:obtain_element(parent_key)
            
            local w, h = gpu.getViewport()
            parent_context.x, parent_context.y, parent_context.w, parent_context.h = 1, 1, w, h
            parent_context.screen_x, parent_context.screen_y, parent_context.screen_w, parent_context.screen_h = 1, 1, w, h
            
            context:remove_not_rendered()
            
            local child_key = parent_context.children[1]
            if child_key ~= nil then
                recursive_recalc_frames(child_key, w, h)
                
                local child_context = context:obtain_element(child_key)
                gpu.fill(1, 1, w, h, " ")
                recursive_draw(child_key, 1, 1, child_context.w, child_context.h, 1, 1, child_context.w, child_context.h)
            end
        end
    end)

    if not status then
        print(err)
    end
end

---@param start_node fun(): Element | "nil"
function gui.start(start_node)
    context = Context()

    global_component = start_node
    render()

    while true do
        -- TODO: replace with functions
        local id, screen_address, x, y, direction_or_button, player_name = event.pullMultiple("touch", "scroll", "interrupted")
        if id == "interrupted" then
            context:set_not_rendered()
            context:remove_not_rendered()
            break
        elseif id == "touch" then
            for i = #context.event_areas, 1, -1 do
                local area = context.event_areas[i]
                if area.event == "on_click" and x >= area.x and x < area.x + area.w and y >= area.y and y < area.y + area.h then
                    local node_context = context:obtain_element(area.node_key)
                    context.events[area.node_key].on_click(player_name, direction_or_button, x - node_context.x + 1, y - node_context.y + 1, node_context.w, node_context.h, node_context.screen_w, node_context.screen_h)
                    i = 0
                end
            end
        elseif id == "scroll" then
            for i = #context.event_areas, 1, -1 do
                local area = context.event_areas[i]
                if area.event == "on_scroll" and x >= area.x and x < area.x + area.w and y >= area.y and y < area.y + area.h then
                    local node_context = context:obtain_element(area.node_key)
                    context.events[area.node_key].on_scroll(player_name, direction_or_button, x - node_context.x + 1, y - node_context.y + 1, node_context.w, node_context.h, node_context.screen_w, node_context.screen_h)
                    i = 0
                end
            end
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
        render()
    end

    return current_state, set_state
end

---@param effect fun(): function?
---@param dependencies any[]?
function gui.use_effect(effect, dependencies)
    local parent = context.parent
    local id = context:get_id_inc()
    local current_context = context:obtain_element(parent)

    local current_cache = current_context.cache[id]
    if current_cache == nil then
        current_cache = {
            dependencies = nil
        }
        current_context.cache[id] = current_cache
    end

    local dependencies_changed = current_cache.dependencies == nil or dependencies == nil or util.any(dependencies, function (dependency, index)
        return current_cache.dependencies == nil or current_cache.dependencies[index] ~= dependency
    end)

    if dependencies_changed then
        if current_cache.cleanup ~= nil then
            current_cache.cleanup()
        end
        current_cache.cleanup = effect()
        current_cache.dependencies = dependencies
    end
end

---@generic T
---@param memo_func fun(): T
---@param dependencies any[]?
---@return T
function gui.use_memo(memo_func, dependencies)
    local parent = context.parent
    local id = context:get_id_inc()
    local current_context = context:obtain_element(parent)

    local current_cache = current_context.cache[id]
    if current_cache == nil then
        current_cache = {
            dependencies = nil
        }
        current_context.cache[id] = current_cache
    end

    local dependencies_changed = current_cache.dependencies == nil or dependencies == nil or util.any(dependencies, function (dependency, index)
        return current_cache.dependencies == nil or current_cache.dependencies[index] ~= dependency
    end)

    if dependencies_changed then
        current_cache.value = memo_func()
        current_cache.dependencies = dependencies
    end

    return current_cache.value
end

---@param callback function
---@param dependencies any[]?
---@return function
function gui.use_callback(callback, dependencies)
    local parent = context.parent
    local id = context:get_id_inc()
    local current_context = context:obtain_element(parent)

    local current_cache = current_context.cache[id]
    if current_cache == nil then
        current_cache = {
            dependencies = nil
        }
        current_context.cache[id] = current_cache
    end

    local dependencies_changed = current_cache.dependencies == nil or dependencies == nil or util.any(dependencies, function (dependency, index)
        return current_cache.dependencies == nil or current_cache.dependencies[index] ~= dependency
    end)

    if dependencies_changed then
        current_cache.value = callback
        current_cache.dependencies = dependencies
    end

    return current_cache.value
end

---@param dependencies any[]?
---@return number
function gui.animate_state(dependencies)
    local parent = context.parent
    local id = context:get_id_inc()
    local current_context = context:obtain_element(parent)

    local current_cache = current_context.cache[id]
    if current_cache == nil then
        current_cache = {
            dependencies = nil
        }
        current_context.cache[id] = current_cache
    end

    local dependencies_changed = current_cache.dependencies == nil or dependencies == nil or util.any(dependencies, function (dependency, index)
        return current_cache.dependencies == nil or current_cache.dependencies[index] ~= dependency
    end)

    if dependencies_changed then
        current_cache.value = 0.0
        current_cache.dependencies = dependencies
    end

    if current_cache.value < 1.0 then
        local event_id = event.timer(0.05, function()
            current_cache.cleanup = nil
            current_cache.value = math.min(1, current_cache.value + 0.05)
            render()
        end)
        current_cache.cleanup = function()
            event.cancel(event_id) 
        end
    end

    return current_cache.value
end

return gui
