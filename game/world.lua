local Chunk = require("game.chunk")

local function chunk_hash(x, y, z)
    return (x * 18397) + (y * 20483) + (z * 29303)
end

---@class World: Class
---@overload fun(): World
local World = Class:extend()

function World:init(scene)
    self.chunks = {}
    self.scene = scene
end

function World:build_chunks()
    for x = 0, WORLD_W -1 do
        for y = 0, WORLD_H -1 do
            for z = 0, WORLD_W -1 do
                local chunk = Chunk(self.scene, x, y, z)
                chunk:build_voxels()
                self.chunks[chunk_hash(x, y, z)] = chunk
                -- local c_index = x + WORLD_W * z + WORLD_AREA * y
                -- self.chunks[c_index+1] = chunk
            end
        end
    end
end

function World:build_chunk_mesh()
    for _, chunk in pairs(self.chunks) do
        if chunk.dirty then
            chunk.dirty = false
            chunk:build_mesh()
        end
    end
end

function World:set_block(bid, x, y, z)
    if y >= MAX_HEIGHT or y < 0 then return false end
    
    x, y, z = math.floor(x), math.floor(y), math.floor(z)
    local chunk = self:get_chunk(x, y, z)
    
    if not chunk then 
        local cx, cy, cz = math.floor(x/CHUNK_SIZE), math.floor(y/CHUNK_SIZE), math.floor(z/CHUNK_SIZE)
        chunk = Chunk(self.scene, cx, cy, cz)
        self.chunks[chunk_hash(cx, cy, cz)] = chunk
    end

    local lx, ly, lz = x - chunk.x, y - chunk.y, z - chunk.z
    chunk:set_block(bid, lx, ly, lz)

    local cx, cy, cz = chunk.cx, chunk.cy, chunk.cz

    if lx == 0 then
        local c = self:get_chunk(x - 1, y, z)
        if c then c:build_mesh() end
    elseif lx == CHUNK_SIZE - 1 then
        local c = self:get_chunk(x + 1, y, z)
        if c then c:build_mesh() end
    end

    if ly == 0 then
        local c = self:get_chunk(x, y - 1, z)
        if c then c:build_mesh() end
    elseif ly == CHUNK_SIZE - 1 then
        local c = self:get_chunk(x, y + 1, z)
        if c then 
            c:build_mesh() 
        end
    end
    
    if lz == 0 then
        local c = self:get_chunk(x, y, z - 1)
        if c then c:build_mesh() end
    elseif lz == CHUNK_SIZE - 1 then
        local c = self:get_chunk(x , y, z + 1)
        if c then c:build_mesh() end
    end
    return true
end

function World:get_block(x, y, z)
    x, y, z = math.floor(x), math.floor(y), math.floor(z)
    local chunk = self:get_chunk(x, y, z)
    if chunk then
        local lx, ly, lz = x - chunk.x, y - chunk.y, z - chunk.z
        return chunk.datapointer[lx + CHUNK_SIZE * lz + CHUNK_AREA * ly]
    end
    return 0
end

function math.sign(x)
    if x == 0 then return 0 end
    return x/math.abs(x)
end

function fract(x)
    return x - math.floor(x)
end

---@deprecated lmaooo let it here just in case yk
function World:ray_intersect(x1, y1, z1, x2, y2, z2)
    -- local px, py, pz = x1, y1, z1
    local px, py, pz = math.floor(x1), math.floor(y1), math.floor(z1)

    --voxel id and normals
    local voxel_id = 0
    local nx, ny, nz = 0, 0, 0

    local dx = math.sign(x2 - x1)
    local delta_x = (dx ~= 0) and math.min(dx / (x2 - x1), 10000000) or 10000000
    local max_x = (dx > 0) and delta_x * (1 - fract(x1)) or delta_x * fract(x1)

    local dy = math.sign(y2 - y1)
    local delta_y = (dy ~= 0) and math.min(dy / (y2 - y1), 10000000) or 10000000
    local max_y = (dy > 0) and delta_y * (1 - fract(y1)) or delta_y * fract(y1)


    local dz = math.sign(z2 - z1)
    local delta_z = (dz ~= 0) and math.min(dz / (z2 - z1), 10000000) or 10000000
    local max_z = (dz > 0) and delta_z * (1 - fract(z1)) or delta_z * fract(z1)

    --- calculando a normal usando a ultima dieração qeu o raio se moveu
    --- se o ultimo movimeto foi no y, quer dizer que o raio foi ppra baixo
    --- ou seja a normla tem que ser pra cima
    local step_dir = -1
    local block = 0

    while not (max_x > 1 and max_y > 1 and max_z > 1) do
        -- local cx, cy, cz = math.floor(px / CHUNK_SIZE), math.floor(py / CHUNK_SIZE), math.floor(pz / CHUNK_SIZE)
        -- local chunk = self.chunks[chunk_hash(cx, cy, cz)]
        -- if chunk then 
        block = self:get_block(px, py, pz)
            -- local lx, ly, lz = px - chunk.x, py - chunk.y, pz - chunk.z
            -- block = chunk:get_block(lx, ly, lz)
            if block ~= 0 then
                voxel_id = block
    
                if step_dir == 0 then
                    nx = -dx
                elseif step_dir == 1 then
                    ny = -dy
                else
                    nz = -dz
                end
                return voxel_id, px, py, pz, nx, ny, nz
            end
        -- end
        if max_x < max_y then
            if max_x < max_z then
                px = px + dx
                max_x = max_x + delta_x
                step_dir = 0
            else
                pz = pz + dz
                max_z = max_z + delta_z
                step_dir = 2
            end
        else
            if max_y < max_z then
                py = py + dy
                max_y = max_y + delta_y
                step_dir = 1
            else
                pz = pz + dz
                max_z = max_z + delta_z
                step_dir = 2
            end
        end
    end
    return 0, math.maxinteger, math.maxinteger, math.maxinteger, nx, ny, nz
end

function World:get_chunk(x, y, z)
    local cx = math.floor(x / CHUNK_SIZE)
    local cy = math.floor(y / CHUNK_SIZE)
    local cz = math.floor(z / CHUNK_SIZE)
    if cy >= MAX_HEIGHT or cy < 0 then
        return nil
    end

    return self.chunks[chunk_hash(cx, cy, cz)]
end

function World:update(dt)
    -- local rd = RENDER_DISTANCE/2

    -- for x = -rd, rd do
    --     for y = -rd, rd do
    --         for z = -rd, rd do
    --             local cx = math.floor(camera.position.x / CHUNK_SIZE) + x
    --             local cy = math.floor(camera.position.y / CHUNK_SIZE) + y
    --             local cz = math.floor(camera.position.z / CHUNK_SIZE) + z
    --             local chunk = self.chunks[chunk_hash(cx, cy, cz)]
    --             if not chunk then
    --                 chunk = Chunk(cx, cy, cz)
    --                 self.chunks[chunk_hash(cx, cy, cz)] = chunk
    --                 chunk:build_voxels()
    --                 chunk:build_mesh()
    --             end
    --         end
    --     end
    -- end
end

local water_shader = love.graphics.newShader("assets/shaders/water.glsl")

function World:draw()
    shader:send("projection", "column", self.scene.camera.projection)
    shader:send("view", "column", self.scene.camera.view_matrix)
    shader:send("block_textures", texture_array)

    for _, chunk in pairs(self.chunks) do
        shader:send("model", "column", chunk.model_matrix)
        chunk:draw()
    end
    local prev = love.graphics.getShader()

    love.graphics.setShader(water_shader)
    
    water_shader:send("projection", "column", self.scene.camera.projection)
    water_shader:send("view", "column", self.scene.camera.view_matrix)
    water_shader:send("time", love.timer.getTime())
    water_shader:send("block_textures", texture_array)
    
    for _, chunk in pairs(self.chunks) do
        water_shader:send("model", "column", chunk.model_matrix)
        chunk:draw_water()
    end

    love.graphics.setShader(prev)
end

return World