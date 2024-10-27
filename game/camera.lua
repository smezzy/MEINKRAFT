local CHUNK_RADIUS = math.floor(CHUNK_SIZE/2) * math.sqrt(3)

local function dot(x1, y1, z1, x2, y2, z2)
    return x1 * x2 + y1 * y2 + z1 * z2
end

local min, max, cos, sin, rad, deg = math.min, math.max, math.cos, math.sin, math.rad, math.deg

---@class Camera
---@overload fun():Camera
---@field projection Mat4
---@field view_matrix Mat4
local Camera = Class:extend()

function Camera:init()
    self.position = vec3(0, 0, 0)
    self.yaw = 90
    self.pitch = 0
    self.direction = vec3.zero
    self.forward = -vec3.unit_z
    self.right = vec3.unit_x
    self.up = vec3.unit_y
    self.mouse_sens = 0.1
    
    self.fov = 70
    self.near = 0.1
    self.far = 1000
    
    self.view_matrix = mat4()
    self:update_projection()
end

function Camera:update_projection()
    self.aspect_ratio = GAME_WIDTH/GAME_HEIGHT
    self.projection = mat4.from_perspective(self.fov, self.aspect_ratio, self.near, self.far)

    -- frustrum
    self.v_fov = math.rad(self.fov) 
    self.h_fov = 2 * math.atan(math.tan(self.v_fov * 0.5) * self.aspect_ratio)

    local half_y = self.v_fov * 0.5
    self.factor_y = 1 / math.cos(half_y)
    self.tan_y = math.tan(half_y)

    local half_x = self.h_fov * 0.5
    self.factor_x = 1 / math.cos(half_x)
    self.tan_x = math.tan(half_x)
end

function Camera:set_fov(new_fov)
    if new_fov == self.fov then return end
    self.fov = new_fov
    self:update_projection()
end

function Camera:update(dt)
    self.yaw = self.yaw + mouse.dx * self.mouse_sens
    self.pitch = self.pitch - mouse.dy * self.mouse_sens

    self.yaw = self.yaw % 360 
    self.pitch = max(min(self.pitch, 89.9), -89.9)

    self.forward.x = cos(rad(self.yaw)) * cos(rad(self.pitch))
    self.forward.y = sin(rad(self.pitch))
    self.forward.z = sin(rad(self.yaw)) * cos(rad(self.pitch))

    self.forward = self.forward:normalize()
    self.direction.x = cos(rad(self.yaw))
    self.direction.z = sin(rad(self.yaw))
    
    self.right = vec3.cross(vec3.unit_y, self.forward):normalize()
    self.up = vec3.cross(self.forward, self.right):normalize()
    mat4.look_at(self.view_matrix, self.position, self.position + self.forward, self.up)
end


function Camera:is_on_frustrum(chunk)
    local svx = (chunk.x + CHUNK_SIZE/2) - self.position.x
    local svy = (chunk.y + CHUNK_SIZE/2) - self.position.y
    local svz = (chunk.z + CHUNK_SIZE/2) - self.position.z

    -- Near and far planes case
    local sz = dot(svx, svy, svz, self.forward.x, self.forward.y, self.forward.z)
    if not (sz >= self.near - CHUNK_RADIUS and sz <= self.far + CHUNK_RADIUS) then
        return false
    end

    -- top and bottom plane case
    local sy = dot(svx, svy, svz, self.up.x, self.up.y, self.up.z)
    local dist = self.factor_y * CHUNK_RADIUS + sz * self.tan_y
    if not (sy >= -dist and sy <= dist) then
        return false
    end

    
    local sx = dot(svx, svy, svz, self.right.x, self.right.y, self.right.z)
    local dist = self.factor_x * CHUNK_RADIUS + sz * self.tan_x
    if not (sx >= -dist and sx <= dist) then
        return false
    end

    return true
end

return Camera   
