
---@class Frustrum
---@overload fun(c: Camera): Frustrum
---@field cam Camera
Frustrum = Class:extend()

function Frustrum:init(camera)
    self.cam = camera
    self:cache_values()
end

function Frustrum:cache_values()
    self.v_fov = math.rad(self.cam.fov) 
    self.h_fov = 2 * math.atan(math.tan(self.v_fov * 0.5) * self.cam.aspect_ratio)

    local half_y = self.v_fov * 0.5
    self.factor_y = 1 / math.cos(half_y)
    self.tan_y = math.tan(half_y)

    local half_x = self.h_fov * 0.5
    self.factor_x = 1 / math.cos(half_x)
    self.tan_x = math.tan(half_x)
end

local function dot(x1, y1, z1, x2, y2, z2)
    return x1 * x2 + y1 * y2 + z1 * z2
end

function Frustrum:is_on_frustrum(chunk)
    local svx = (chunk.x + CHUNK_SIZE/2) - self.cam.position.x
    local svy = (chunk.y + CHUNK_SIZE/2) - self.cam.position.y
    local svz = (chunk.z + CHUNK_SIZE/2) - self.cam.position.z

    -- Near and far planes case
    local sz = dot(svx, svy, svz, self.cam.forward.x, self.cam.forward.y, self.cam.forward.z)
    if not (sz >= self.cam.near - CHUNK_RADIUS and sz <= self.cam.far + CHUNK_RADIUS) then
        return false
    end

    -- top and bottom plane case
    local sy = dot(svx, svy, svz, self.cam.up.x, self.cam.up.y, self.cam.up.z)
    local dist = self.factor_y * CHUNK_RADIUS + sz * self.tan_y
    if not (sy >= -dist and sy <= dist) then
        return false
    end

    
    local sx = dot(svx, svy, svz, self.cam.right.x, self.cam.right.y, self.cam.right.z)
    local dist = self.factor_x * CHUNK_RADIUS + sz * self.tan_x
    if not (sx >= -dist and sx <= dist) then
        return false
    end

    return true
end

return Frustrum