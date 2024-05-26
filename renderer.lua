local math = require("math")

local component = require("component")
local gpu = component.gpu

---@class Renderer
---@field private x integer
---@field private y integer
---@field private w integer
---@field private h integer
---
---@field get_w fun(self: Renderer): integer
---@field get_h fun(self: Renderer): integer
---@field set_background fun(color: number): number
---@field set_foreground fun(color: number): number
---@field set fun(self: Renderer, x: number, y: number, value: string, vertical: boolean?)
---@field get fun(self: Renderer, x: number, y: number): string?, number?, number?
---@field fill fun(self: Renderer, x: number, y: number, width: number, height: number, char: string)
---@field copy fun(self: Renderer, x: number, y: number, width: number, height: number, tx: number, ty: number)

---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return Renderer
return function(x, y, w, h)
    local Renderer = {
        x = x,
        y = y,
        w = w,
        h = h
    }

    function Renderer.get_w(self)
        return self.w
    end

    function Renderer.get_h(self)
        return self.h
    end

    function Renderer.set_background(color)
        return gpu.setBackground(color)
    end

    function Renderer.set_foreground(color)
        return gpu.setForeground(color)
    end

    function Renderer.set(self, x, y, value, vertical)
        if x >= 1 and x <= self.w and y >= 1 and y <= self.h then
            local value_len = string.len(value)
    
            local cut_value
            if vertical then
                cut_value = string.sub(value, 1, math.min(value_len, self.h - y + 1))
            else
                cut_value = string.sub(value, 1, math.min(value_len, self.w - x + 1))
            end
            
            gpu.set(self.x + x - 1, self.y + y - 1, cut_value, vertical)
        end
    end

    function Renderer.get(self, x, y)
        if x >= 1 and x <= self.w and y >= 1 and y <= self.h then
            return gpu.get(self.x + x - 1, self.y + y - 1)
        else
            return nil, nil, nil
        end
    end

    function Renderer.fill(self, x, y, width, height, char)
        if x >= 1 and x <= self.w and y >= 1 and y <= self.h then
            gpu.fill(self.x + x - 1, self.y + y - 1, math.min(width, self.w - x + 1), math.min(height, self.h - y + 1), char)
        end
    end

    function Renderer.copy(self, x, y, width, height, tx, ty)
        if x >= 1 and x <= self.w and y >= 1 and y <= self.h and tx >= 1 and tx <= self.w and ty >= 1 and ty <= self.h then
            local cut_width = math.min(width, self.w - x + 1, self.w - tx + 1)
            local cut_height = math.min(height, self.h - y + 1, self.h - ty + 1)

            gpu.copy(self.x + x - 1, self.y + y - 1, cut_width, cut_height, self.x + tx - 1, self.y + ty - 1)
        end
    end

    return Renderer
end