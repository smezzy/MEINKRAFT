local air_or_liquid = require("game.blockinfo").air_or_liquid

local function input_axis(negative, positive)
    local x = 0
end

local GameObject = require("game.gameobject")
---@class Player: GameObject
---@overload fun(x, y): Player
---@field position Vec3
---@field world World
---@field camera Camera
local Player = GameObject:extend()

function Player:init(scene, x, y, z)
    GameObject.init(self, x, y, z)

    self.world = scene.world
    self.camera = scene.camera
    self.speed = 16

    self.hit_range = HIT_RANGE
    self.ray = require("game.ray")(self.world)
    self.marker = require("game.marker")(self.camera)
end

function Player:update(dt)
    GameObject.update(self, dt)

    if love.keyboard.isDown("lctrl") then
        self.speed = 48
        self.camera:set_fov(75)
    else
        self.speed = 16
        self.camera:set_fov(70)
    end

    if love.keyboard.isDown("w") then
        self.position = self.position + self.camera.direction * self.speed * dt    
    elseif love.keyboard.isDown("s") then
        self.position = self.position - self.camera.direction * self.speed * dt    
    end

    if love.keyboard.isDown("a") then
        self.position = self.position + self.camera.right * self.speed * dt    
    elseif love.keyboard.isDown("d") then
        self.position = self.position - self.camera.right * self.speed * dt    
    end

    if love.keyboard.isDown("lshift") then
        self.position = self.position - vec3.unit_y * self.speed * dt    
    elseif love.keyboard.isDown("space") then
        self.position = self.position +  vec3.unit_y * self.speed * dt    
    end

    self.camera.position = self.position

    self:update_ray()

    if input:pressed("m1") then
        local ray = self.ray
        if not air_or_liquid[ray.bid] then
            self.world:set_block(0, ray.px, ray.py, ray.pz)
        end
    elseif input:pressed("m2") then
        local ray = self.ray
        local x, y, z = ray.px + ray.nx, ray.py + ray.ny, ray.pz + ray.nz
        local block = self.world:get_block(x, y, z)
        if air_or_liquid[block] then
            self.world:set_block(2, x, y, z)
        end
    end
end

function Player:update_ray()
    self.ray:set_position(self.camera.position, self.camera.forward, self.hit_range)
    self.ray:block_intersect()
    local bx, by, bz = math.floor(self.ray.px), math.floor(self.ray.py), math.floor(self.ray.pz)

    -- if not air_or_liquid[self.ray.bid] then
    self.marker:update_position(self.ray.bid, bx, by, bz)
    -- end
end

function Player:draw()
end


return Player
