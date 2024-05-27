local math = require("math")

local component = require("component")
local gpu = component.gpu

---@class Renderer
---@field private virtual_x integer
---@field private virtual_y integer
---@field private virtual_w integer
---@field private virtual_h integer
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

---@param virtual_x integer
---@param virtual_y integer
---@param virtual_w integer
---@param virtual_h integer
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return Renderer
return function(virtual_x, virtual_y, virtual_w, virtual_h, x, y, w, h)
    local Renderer = {
        virtual_x = virtual_x,
        virtual_y = virtual_y,
        virtual_w = virtual_w,
        virtual_h = virtual_h,
        x = x,
        y = y,
        w = w,
        h = h
    }

    function Renderer.get_w(self)
        return self.virtual_w
    end

    function Renderer.get_h(self)
        return self.virtual_h
    end

    function Renderer.set_background(color)
        return gpu.setBackground(color)
    end

    function Renderer.set_foreground(color)
        return gpu.setForeground(color)
    end

    function Renderer.set(self, x, y, value, vertical)
        local value_len = string.len(value)

        local x = x - (self.x - self.virtual_x)
        local y = y - (self.y - self.virtual_y)

        local cut_value
        if vertical then
            cut_value = string.sub(value, 1, math.min(value_len, self.h - y + 1))
            cut_value = string.sub(cut_value, math.max(1, 2 - y), value_len)
        else
            cut_value = string.sub(value, 1, math.min(value_len, self.w - x + 1))
            cut_value = string.sub(cut_value, math.max(1, 2 - x), value_len)
        end

        if (vertical and x >= 1 and x <= self.w) or (not vertical and y >= 1 and y <= self.h) then
            gpu.set(math.max(self.x, self.x + x - 1), math.max(self.y, self.y + y - 1), cut_value, vertical)
        end
    end

    function Renderer.get(self, x, y)
        local x = x - (self.x - self.virtual_x)
        local y = y - (self.y - self.virtual_y)

        if x >= 1 and x <= self.w and y >= 1 and y <= self.h then
            return gpu.get(self.x + x - 1, self.y + y - 1)
        else
            return nil, nil, nil
        end
    end

    function Renderer.fill(self, x, y, width, height, char)
        local x = x - (self.x - self.virtual_x)
        local y = y - (self.y - self.virtual_y)

        gpu.fill(math.max(self.x, self.x + x - 1), math.max(self.y, self.y + y - 1), math.min(width, self.w - x + 1), math.min(height, self.h - y + 1), char)
    end

    function Renderer.copy(self, x, y, width, height, tx, ty)
        local x = x - (self.x - self.virtual_x)
        local y = y - (self.y - self.virtual_y)
        local tx = tx - (self.x - self.virtual_x)
        local ty = ty - (self.y - self.virtual_y)

        if x >= 1 and x <= self.w and y >= 1 and y <= self.h and tx >= 1 and tx <= self.w and ty >= 1 and ty <= self.h then
            local cut_width = math.min(width, self.w - x + 1, self.w - tx + 1)
            local cut_height = math.min(height, self.h - y + 1, self.h - ty + 1)

            gpu.copy(self.x + x - 1, self.y + y - 1, cut_width, cut_height, self.x + tx - 1, self.y + ty - 1)
        end
    end

    return Renderer
end