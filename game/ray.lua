local air_or_liquid = require("game.blockinfo").air_or_liquid

---@class Ray
---@overload fun(world: World): Ray
---@field world World
local Ray = Class:extend()

function Ray:init(world)
    self.world = world
    -- starting position
    self.x1 = 0
    self.y1 = 0
    self.z1 = 0
    
    -- end position
    self.x2 = 0
    self.y2 = 0
    self.z2 = 0

    -- current position not floored
    self.px = 0
    self.py = 0
    self.pz = 0
    
    -- block id where its at and the normal
    self.bid = 0
    self.nx = 0
    self.ny = 0
    self.nz = 0

    self.detect_liquid = false
end

function Ray:set_position(start, direction, distance)
    self.x1, self.y1, self.z1 = start.x, start.y, start.z

    self.x2 = start.x + direction.x * HIT_RANGE
    self.y2 = start.y + direction.y * HIT_RANGE
    self.z2 = start.z + direction.z * HIT_RANGE
end

function Ray:is_solid(bid)
    if self.detect_liquid then
        return bid ~= 0
    else
        return not air_or_liquid[bid]
    end
end

function Ray:block_intersect()
    self.px, self.py, self.pz = math.floor(self.x1), math.floor(self.y1), math.floor(self.z1)

    local dx = math.sign(self.x2 - self.x1)
    local delta_x = (dx ~= 0) and math.min(dx / (self.x2 - self.x1), 10000000) or 10000000
    local max_x = (dx > 0) and delta_x * (1 - fract(self.x1)) or delta_x * fract(self.x1)

    local dy = math.sign(self.y2 - self.y1)
    local delta_y = (dy ~= 0) and math.min(dy / (self.y2 - self.y1), 10000000) or 10000000
    local max_y = (dy > 0) and delta_y * (1 - fract(self.y1)) or delta_y * fract(self.y1)

    local dz = math.sign(self.z2 - self.z1)
    local delta_z = (dz ~= 0) and math.min(dz / (self.z2 - self.z1), 10000000) or 10000000
    local max_z = (dz > 0) and delta_z * (1 - fract(self.z1)) or delta_z * fract(self.z1)

    --- calculando a normal usando a ultima dieração qeu o raio se moveu
    --- se o ultimo movimeto foi no y, quer dizer que o raio foi ppra baixo
    --- ou seja a normla tem que ser pra cima
    local step_dir = -1
    self.nx, self.ny, self.nz = 0, 0, 0

    while not (max_x > 1 and max_y > 1 and max_z > 1) do
        self.bid = self.world:get_block(self.px, self.py, self.pz)
        if self:is_solid(self.bid) then
            if step_dir == 0 then
                self.nx = -dx
            elseif step_dir == 1 then
                self.ny = -dy
            else
                self.nz = -dz
            end
            return
        end

        if max_x < max_y then
            if max_x < max_z then
                self.px = self.px + dx
                max_x = max_x + delta_x
                step_dir = 0
            else
                self.pz = self.pz + dz
                max_z = max_z + delta_z
                step_dir = 2
            end
        else
            if max_y < max_z then
                self.py = self.py + dy
                max_y = max_y + delta_y
                step_dir = 1
            else
                self.pz = self.pz + dz
                max_z = max_z + delta_z
                step_dir = 2
            end
        end
    end
    self.bid = 0
end

return Ray