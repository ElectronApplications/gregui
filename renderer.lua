local math = require("math")

local component = require("component")
local gpu = component.gpu

---@class Renderer
---@field private x integer
---@field private y integer
---@field private w integer
---@field private h integer
---@field private screen_x integer
---@field private screen_y integer
---@field private screen_w integer
---@field private screen_h integer
---
---@field get_w fun(self: Renderer): integer
---@field get_h fun(self: Renderer): integer
---@field get_screen_w fun(self: Renderer): integer
---@field get_screen_h fun(self: Renderer): integer
---@field set_background fun(color: number): number
---@field set_foreground fun(color: number): number
---@field set fun(self: Renderer, x: number, y: number, value: string, vertical: boolean?)
---@field get fun(self: Renderer, x: number, y: number): string?, number?, number?
---@field fill fun(self: Renderer, x: number, y: number, width: number, height: number, char: string)

---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param screen_x integer
---@param screen_y integer
---@param screen_w integer
---@param screen_h integer
---@return Renderer
return function(x, y, w, h, screen_x, screen_y, screen_w, screen_h)
    local Renderer = {
        x = x,
        y = y,
        w = w,
        h = h,
        screen_x = screen_x,
        screen_y = screen_y,
        screen_w = screen_w,
        screen_h = screen_h
    }

    function Renderer.get_w(self)
        return self.w
    end

    function Renderer.get_h(self)
        return self.h
    end

    function Renderer.get_screen_w(self)
        return self.screen_w
    end

    function Renderer.get_screen_h(self)
        return self.screen_h
    end

    function Renderer.set_background(color)
        return gpu.setBackground(color)
    end

    function Renderer.set_foreground(color)
        return gpu.setForeground(color)
    end

    function Renderer.set(self, x, y, value, vertical)
        local value_len = string.len(value)

        local x = x - (self.screen_x - self.x)
        local y = y - (self.screen_y - self.y)

        local cut_value
        if vertical then
            cut_value = string.sub(value, 1, math.min(value_len, self.screen_h - y + 1))
            cut_value = string.sub(cut_value, math.max(1, 2 - y), value_len)
        else
            cut_value = string.sub(value, 1, math.min(value_len, self.screen_w - x + 1))
            cut_value = string.sub(cut_value, math.max(1, 2 - x), value_len)
        end

        if (vertical and x >= 1 and x <= self.screen_w) or (not vertical and y >= 1 and y <= self.screen_h) then
            gpu.set(math.max(self.screen_x, self.screen_x + x - 1), math.max(self.screen_y, self.screen_y + y - 1), cut_value, vertical)
        end
    end

    function Renderer.get(self, x, y)
        local x = x - (self.screen_x - self.x)
        local y = y - (self.screen_y - self.y)

        if x >= 1 and x <= self.screen_w and y >= 1 and y <= self.screen_h then
            return gpu.get(self.screen_x + x - 1, self.screen_y + y - 1)
        else
            return nil, nil, nil
        end
    end

    function Renderer.fill(self, x, y, width, height, char)
        local x = x - (self.screen_x - self.x)
        local y = y - (self.screen_y - self.y)

        local in_x = math.max(self.screen_x, self.screen_x + x - 1)
        local in_y = math.max(self.screen_y, self.screen_y + y - 1)
        local in_w = math.min(self.screen_w - math.max(1, x) + 1, x + width - 1)
        local in_h = math.min(self.screen_h - math.max(1, y) + 1, y + height - 1)

        gpu.fill(in_x, in_y, in_w, in_h, char)
    end

    return Renderer
end