---@class GameObject
---@overload fun(x, y, z): GameObject
---@field position Vec3
---@field rotation Vec3
---@field scale Vec3
local GameObject = Class:extend()

function GameObject:init(x, y, z)
    self.position = vec3(x, y, z)
    self.rotation = vec3()
    self.scale = vec3()
    self.dead = false
end

function GameObject:update(dt)
    -- go.timer:update(dt)
    -- go.spring:update(dt)
end


function GameObject:draw()
end


return GameObject
