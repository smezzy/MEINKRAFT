--- MINECRAFT CLONE BASED HARD BADASS
GAME_WIDTH, GAME_HEIGHT = love.graphics.getDimensions()
CHUNK_SIZE = 32
CHUNK_AREA = CHUNK_SIZE*CHUNK_SIZE
MAX_HEIGHT = 256
WORLD_W = 4
WORLD_H = MAX_HEIGHT/CHUNK_SIZE
WORLD_AREA = WORLD_W*WORLD_W
WORLD_VOL = WORLD_AREA*WORLD_H
RENDER_DISTANCE = 6
HIT_RANGE = 6 -- idk how this range works tbh just gonna guess some value

require("libraries")

love.graphics.setDefaultFilter('nearest', 'nearest')

function love.load()
    --configuration
    local font = love.graphics.newFont("assets/fonts/Minecraft.ttf", 16)
    love.graphics.setFont(font)
    love.graphics.setDepthMode("lequal", true)
    love.graphics.setMeshCullMode("back")
    love.window.setVSync(false)
    love.mouse.setRelativeMode(true)

    input = baton.new(require "controls")

    shader = love.graphics.newShader("assets/shaders/shader.glsl")
    crosshair = love.graphics.newImage("assets/textures/crosshair.png")

    scene = require("game.scene")()
    
    mouse = {
        x = 0, y = 0,
        lx = 0, ly = 0,
        dx = 0, dy = 0,
    }
end

function love.mousemoved(x, y, dx, dy, istouch)
    mouse.dx = dx
    mouse.dy = dy
end


function love.resize(w, h)
    GAME_WIDTH, GAME_HEIGHT = w, h
    scene.camera:update_projection()
end

function love.keypressed(key)
    if key == 'f4' then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end

function love.mousepressed(x, y, btn, istouch)
end

block_list = require("blocks")
local models = require("models")
local glass = table.copy(models.cube)
glass.transparent = true

local texture_index = 1
local texture_hash = {}
local textures = {
    "assets/textures/blocks/missing_texture.png"
}
for id, block in ipairs(block_list) do
    block.id = id
    block.texture_ids = {}
    for _, tex in ipairs(block[3]) do
        local texture_id
        if texture_hash[tex] then
            texture_id = texture_hash[tex]
        else
            texture_hash[tex] = texture_index
            texture_id = texture_index
            texture_index = texture_index + 1
            table.insert(textures, tex)
        end
        table.insert(block.texture_ids, texture_id)
    end
end

for i = 2, #textures do
    local tex = textures[i]
    textures[i] = "assets/textures/blocks/"..tex..".png"
end

print("aconteceu alguam coisa...")
texture_array = love.graphics.newArrayImage(textures)
textures = nil
texture_hash = nil

local freq = 0
local title = love.window.getTitle()
local pbx, pby, pbz
function love.update(dt)
    input:update(dt)
    scene:update(dt)
    -- world:update(dt)
    -- camera:update(dt)
    -- player:update(dt)

    freq = freq + dt
    if freq > 1 then
        freq = 0
        love.window.setTitle(title .. " | FPS: " .. love.timer.getFPS())
    end

    mouse.x, mouse.y = love.mouse.getPosition()
    mouse.dx, mouse.dy = 0 , 0
end


function love.draw()
    love.graphics.clear(150/255, 255/255, 255/255)
    love.graphics.setShader(shader)
    
    scene:draw()
    -- world:draw()
    -- marker:draw()

    love.graphics.setShader()

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.draw(crosshair, GAME_WIDTH/2, GAME_HEIGHT/2, 0, 1, 1)

    love.graphics.setColor(1, 1, 1, 1)
end
