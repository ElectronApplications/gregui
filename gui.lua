local math = require("math")
local component = require("component")
local gpu = component.gpu

local util = require("gregui.util")

local gui = {}

---@type integer
local global_id = 0

---@type string
local global_parent = ""

local global_context = {}


---@class ComposableElement
---@field type "composable"
---@field element fun(props: table): Element
---@field props table
---@field key string

---@alias coordinates_callback_function fun(width: integer, height: integer): (integer, integer)
---@alias render_callback_function fun(element: Element, max_width: integer, max_height: integer, coordinates_callback: coordinates_callback_function)
---@alias render_function fun(width: integer, height: integer, render_callback: render_callback_function): (integer, integer)

---@class DrawableElement
---@field type "drawable"
---@field render render_function
---@field max_width integer
---@field max_height integer

---@alias Element ComposableElement | DrawableElement


---@param element fun(props: table): Element
---@param props table
---@return ComposableElement
function gui.create_element(element, props)
    local element_object = {
        type = "composable",
        element = element,
        props = props
    }
    local id = global_id

    if util.contains(props, "key") then
        element_object.key = global_parent .. "_" .. id .. "_key_" .. props["key"]
    else
        element_object.key = global_parent .. "_" .. id
        global_id = global_id + 1
    end

    return element_object
end

---@param render render_function
---@param max_width integer
---@param max_height integer
---@return DrawableElement
function gui.create_drawable_element(render, max_width, max_height)
    local element_object = {
        type = "drawable",
        render = render,
        max_width = max_width,
        max_height = max_height
    }

    return element_object
end


---@param node Element
---@param max_width integer
---@param max_height integer
---@param coordinates_callback coordinates_callback_function
---@return integer, integer
local function recursive_render(node, max_width, max_height, coordinates_callback)
    if node.type == "composable" then
        global_parent = node.key
        global_id = 0
        return recursive_render(node.element(node.props), max_width, max_height, coordinates_callback)
    else
        local width = (node.max_width < 0 and {max_width} or {math.min(node.max_width, max_width)})[1]
        local height = (node.max_height < 0 and {max_height} or {math.min(node.max_height, max_height)})[1]
        
        local current_buffer = gpu.getActiveBuffer()
        local buffer = gpu.allocateBuffer(width, height)
        gpu.setActiveBuffer(buffer)
        
        width, height = node.render(width, height, function (element, max_width, max_height, coordinates_callback)
            recursive_render(element, max_width, max_height, coordinates_callback)
        end)
        
        local x, y = coordinates_callback(width, height)
        gpu.bitblt(current_buffer, x, y, width, height, buffer, 1, 1)    

        gpu.setActiveBuffer(current_buffer)
        gpu.freeBuffer(buffer)

        return width, height
    end
end

---@param element fun(): Element
function gui.render(element)
    local status, err = pcall(function()
        local w, h = gpu.getResolution()
        recursive_render(element(), w, h, function(width, height)
            return 1, 1
        end)
    end)

    if not status then
        gpu.freeAllBuffers()
        print(err)
    end
end

return gui
