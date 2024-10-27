-- chunk formula : x + CHUNK_SIZE * z + CHUNK_AREA * y
-- vertex_format = {
--     {"VertexPosition", "float", 3},
--     {"VertexTexCoord", "float", 3},
--     {"VertexShade", "float", 1 },
--     {"VertexNormal", "float", 3},
--     {"VertexColor", "byte", 4},
-- }

vertex_format = {
    { "VertexPosition", "float", 3 },
    { "TexId",          "float", 1 },
    { "PackedData",     "byte",  4 },
}

-- vertex_format = {
--     {"VertexPosition", "float", 3},
--     {"VoxelId", "float", 1},
--     {"FaceId", "float", 1},
--     {"AmbientOcclusionId", "float", 1},
--     {"FlipId", "float", 1}
-- }

-- TODO ISSO AQ VAI DA PROBLEMA PROVAVELMENTE !! kk
local ffi = require("ffi")
ffi.cdef([[
    struct vertex {
        float x, y, z, tex_id;
        uint8_t voxel_id, face_id, ambient_occlusion, flip_id;
    }
]])

-- this is not very optmized i think
local function is_opaque(block_id)
    local block_info = block_list[block_id]
    if block_id <= 0 or block_id == 9 then return false end
    if block_info then
        if block_info[2].transparent then
            return false
        end
    end
    return true
end

local function is_void(block_id)
    local block_info = block_list[block_id]
    if block_id == 0 or block_id == 9 then return 1 end
    if block_info then
        if block_info[2].transparent then
            return 1
        end
    end
    return 0
end

local function create_vertex(x, y, z, bid, face_id, ao, flip)
    local vertex = ffi.new("struct vertex")
    vertex.x = x
    vertex.y = y
    vertex.z = z
    local block_info = block_list[bid]
    local default = 0
    local tex_id = default
    if block_info then
        tex_id = block_info.texture_ids[1]
        if face_id == 0 then
            tex_id = block_info.texture_ids[2] or tex_id
        elseif face_id == 1 then
            tex_id = block_info.texture_ids[3] or tex_id
        end
    end
    vertex.tex_id = tex_id or default
    vertex.voxel_id = bid
    vertex.face_id = face_id
    vertex.ambient_occlusion = ao
    vertex.flip_id = flip
    return vertex
end

local TerrainGen = require("game.terrain")
local gen = TerrainGen()

---@class Chunk: Class
---@overload fun(): Chunk
---@field world World
local Chunk = Class:extend()

function Chunk:init(scene, x, y, z)
    self.camera = scene.camera
    self.world = scene.world
    self.mesh = nil
    self.cx = x
    self.cy = y
    self.cz = z
    self.x = x * CHUNK_SIZE
    self.y = y * CHUNK_SIZE
    self.z = z * CHUNK_SIZE
    self.dirty = true
    self.model_matrix = mat4():translate(mat4(), vec3(self.x, self.y, self.z))

    local data = love.data.newByteData(ffi.sizeof("uint8_t") * CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE)
    self.data = data
    self.datapointer = ffi.cast("uint8_t*", data:getFFIPointer())
end

function Chunk:get_ao(x, y, z, plane)
    -- plane Y = 1, X = 2, Z = 3
    local a, b, c, d, e, f, g, h
    if plane == 1 then
        a = is_void(self:get_block(x, y, z - 1))
        b = is_void(self:get_block(x - 1, y, z - 1))
        c = is_void(self:get_block(x - 1, y, z))
        d = is_void(self:get_block(x - 1, y, z + 1))
        e = is_void(self:get_block(x, y, z + 1))
        f = is_void(self:get_block(x + 1, y, z + 1))
        g = is_void(self:get_block(x + 1, y, z))
        h = is_void(self:get_block(x + 1, y, z - 1))
    elseif plane == 2 then
        a = is_void(self:get_block(x, y, z - 1))
        b = is_void(self:get_block(x, y - 1, z - 1))
        c = is_void(self:get_block(x, y - 1, z))
        d = is_void(self:get_block(x, y - 1, z + 1))
        e = is_void(self:get_block(x, y, z + 1))
        f = is_void(self:get_block(x, y + 1, z + 1))
        g = is_void(self:get_block(x, y + 1, z))
        h = is_void(self:get_block(x, y + 1, z - 1))
    elseif plane == 3 then
        a = is_void(self:get_block(x - 1, y, z))
        b = is_void(self:get_block(x - 1, y - 1, z))
        c = is_void(self:get_block(x, y - 1, z))
        d = is_void(self:get_block(x + 1, y - 1, z))
        e = is_void(self:get_block(x + 1, y, z))
        f = is_void(self:get_block(x + 1, y + 1, z))
        g = is_void(self:get_block(x, y + 1, z))
        h = is_void(self:get_block(x - 1, y + 1, z))
    end

    return (a + b + c), (g + h + a), (e + f + g), (c + d + e)
end

function Chunk:build_voxels()
    for x = 0, CHUNK_SIZE - 1 do
        for z = 0, CHUNK_SIZE - 1 do
            local wx, wz = x + self.x, z + self.z

            local elevation = gen:get_elevation(wx, wz)

            local world_height = math.floor(elevation * 128)
            local local_height = math.min(world_height - self.y, CHUNK_SIZE)

            for y = 0, local_height - 1 do
                local wy = self.y + y
                self.datapointer[x + CHUNK_SIZE * z + CHUNK_AREA * y] = 10
            end
        end
    end

    for x = 0, CHUNK_SIZE - 1 do
        for y = 0, CHUNK_SIZE - 1 do
            for z = 0, CHUNK_SIZE - 1 do
                local wx = self.x + x
                local wy = self.y + y
                local wz = self.z + z

                local moist = gen:get_moist(wx, wz)
                local biome = gen:get_biome(wy / 128, moist)

                if biome == BIOME.WATER then
                    local i = x + CHUNK_SIZE * z + CHUNK_AREA * y
                    local block = self.datapointer[i]
                    if block == 0 then
                        self.datapointer[i] = 9
                    end
                end
            end
        end
    end

    for x = 0, CHUNK_SIZE - 1 do
        for y = 0, CHUNK_SIZE - 1 do
            for z = 0, CHUNK_SIZE - 1 do
                local wx = self.x + x
                local wy = self.y + y
                local wz = self.z + z
                local i = x + CHUNK_SIZE * z + CHUNK_AREA * y
                local block = self.datapointer[i]
                if block ~= 0 then
                    local moist = gen:get_moist(wx, wz)
                    local biome = gen:get_biome(wy / 128, moist)

                    if biome == BIOME.BEACH or biome == BIOME.WATER and block ~= 9 then
                        self.datapointer[i] = 4
                    elseif biome == BIOME.TESTE then
                        self.datapointer[i] = 7
                    elseif biome == BIOME.FOREST then
                        if self:get_block(x, y + 1, z) == 0 then
                            self.datapointer[i] = 1
                        else
                            self.datapointer[i] = 2
                        end
                    end
                end
            end
        end
    end
end

function Chunk:build_mesh()

    local function solid_opaque_fn(bid)
        return not is_opaque(bid)
    end

    local face_count = 0
    for x = 0, CHUNK_SIZE - 1 do
        for y = 0, CHUNK_SIZE - 1 do
            for z = 0, CHUNK_SIZE - 1 do
                local block_id = self:get_block(x, y, z)
                if block_id ~= 0 and block_id ~= 9 then
                    if solid_opaque_fn(self:get_block(x + 1, y, z)) then face_count = face_count + 1 end
                    if solid_opaque_fn(self:get_block(x - 1, y, z)) then face_count = face_count + 1 end
                    if solid_opaque_fn(self:get_block(x, y + 1, z)) then face_count = face_count + 1 end
                    if solid_opaque_fn(self:get_block(x, y - 1, z)) then face_count = face_count + 1 end
                    if solid_opaque_fn(self:get_block(x, y, z + 1)) then face_count = face_count + 1 end
                    if solid_opaque_fn(self:get_block(x, y, z - 1)) then face_count = face_count + 1 end
                end
            end
        end
    end

    local function water_opaque_fn(bid)
        return bid <= 0 
    end

    local water_face_count = 0
    for x = 0, CHUNK_SIZE - 1 do
        for y = 0, CHUNK_SIZE - 1 do
            for z = 0, CHUNK_SIZE - 1 do
                local block_id = self:get_block(x, y, z)
                if block_id == 9 then
                    if water_opaque_fn(self:get_block(x + 1, y, z))  then water_face_count = water_face_count + 1 end
                    if water_opaque_fn(self:get_block(x - 1, y, z))  then water_face_count = water_face_count + 1 end
                    if water_opaque_fn(self:get_block(x, y + 1, z))  then water_face_count = water_face_count + 1 end
                    if water_opaque_fn(self:get_block(x, y - 1, z))  then water_face_count = water_face_count + 1 end
                    if water_opaque_fn(self:get_block(x, y, z + 1))  then water_face_count = water_face_count + 1 end
                    if water_opaque_fn(self:get_block(x, y, z - 1))  then water_face_count = water_face_count + 1 end
                end
            end
        end
    end

    if face_count > 0 then 
        local vertex_data = love.data.newByteData(face_count * 6 * ffi.sizeof("struct vertex"))
        local datapointer = ffi.cast("struct vertex *", vertex_data:getFFIPointer())
    
        self:create_mesh_data(datapointer, function(bid) return bid ~= 0 and bid ~= 9 end, solid_opaque_fn)
        
        self.mesh = love.graphics.newMesh(vertex_format, face_count * 6, "triangles", "static")
        self.mesh:setVertices(vertex_data)
        vertex_data:release()
    end

    if water_face_count > 0 then
        local vertex_data = love.data.newByteData(water_face_count * 6 * ffi.sizeof("struct vertex"))
        local datapointer = ffi.cast("struct vertex *", vertex_data:getFFIPointer())
    
        self:create_mesh_data(datapointer, function(bid) return bid == 9 end, water_opaque_fn)
        
        self.water_mesh = love.graphics.newMesh(vertex_format, water_face_count * 6, "triangles", "static")
        self.water_mesh:setVertices(vertex_data)
        vertex_data:release()
    end
end

function Chunk:create_mesh_data(datapointer, validate, opaque_fn)
    local dataindex = 0

    local function add_data(v1, v2, v3, v4, v5, v6)
        datapointer[dataindex + 0] = v1
        datapointer[dataindex + 1] = v2
        datapointer[dataindex + 2] = v3
        datapointer[dataindex + 3] = v4
        datapointer[dataindex + 4] = v5
        datapointer[dataindex + 5] = v6
        dataindex = dataindex + 6
    end

    for x = 0, CHUNK_SIZE - 1 do
        for y = 0, CHUNK_SIZE - 1 do
            for z = 0, CHUNK_SIZE - 1 do
                local bid = self:get_block(x, y, z)
                if validate(bid) then
                    local right = self:get_block(x + 1, y, z)
                    local left  = self:get_block(x - 1, y, z)
                    local up    = self:get_block(x, y + 1, z)
                    local down  = self:get_block(x, y - 1, z)
                    local back  = self:get_block(x, y, z - 1)
                    local front = self:get_block(x, y, z + 1)

                    if opaque_fn(up) then
                        local ao0, ao1, ao2, ao3 = self:get_ao(x, y + 1, z, 1)
                        local flip = (ao1 + ao3 > ao0 + ao2) and 1 or 0


                        local v0 = create_vertex(x, y + 1, z, bid, 0, ao0, flip)
                        local v1 = create_vertex(x + 1, y + 1, z, bid, 0, ao1, flip)
                        local v2 = create_vertex(x + 1, y + 1, z + 1, bid, 0, ao2, flip)
                        local v3 = create_vertex(x, y + 1, z + 1, bid, 0, ao3, flip)

                        if flip == 1 then
                            add_data(v1, v0, v3, v1, v3, v2)
                        else
                            add_data(v0, v3, v2, v0, v2, v1)
                        end
                    end

                    if opaque_fn(down) then
                        local ao0, ao1, ao2, ao3 = self:get_ao(x, y - 1, z, 1)
                        local flip = (ao1 + ao3 > ao0 + ao2) and 1 or 0

                        local v0 = create_vertex(x, y, z, bid, 1, ao0, flip)
                        local v1 = create_vertex(x + 1, y, z, bid, 1, ao1, flip)
                        local v2 = create_vertex(x + 1, y, z + 1, bid, 1, ao2, flip)
                        local v3 = create_vertex(x, y, z + 1, bid, 1, ao3, flip)

                        if flip == 1 then
                            add_data(v1, v3, v0, v1, v2, v3)
                        else
                            add_data(v0, v2, v3, v0, v1, v2)
                        end
                    end

                    if opaque_fn(right) then
                        local ao0, ao1, ao2, ao3 = self:get_ao(x + 1, y, z, 2)
                        local flip = (ao1 + ao3 > ao0 + ao2) and 1 or 0

                        local v0 = create_vertex(x + 1, y, z, bid, 2, ao0, flip)
                        local v1 = create_vertex(x + 1, y + 1, z, bid, 2, ao1, flip)
                        local v2 = create_vertex(x + 1, y + 1, z + 1, bid, 2, ao2, flip)
                        local v3 = create_vertex(x + 1, y, z + 1, bid, 2, ao3, flip)

                        if flip == 1 then
                            add_data(v3, v0, v1, v3, v1, v2)
                        else
                            add_data(v0, v1, v2, v0, v2, v3)
                        end
                    end

                    if opaque_fn(left) then
                        local ao0, ao1, ao2, ao3 = self:get_ao(x - 1, y, z, 2)
                        local flip = (ao1 + ao3 > ao0 + ao2) and 1 or 0

                        local v0 = create_vertex(x, y, z, bid, 3, ao0, flip)
                        local v1 = create_vertex(x, y + 1, z, bid, 3, ao1, flip)
                        local v2 = create_vertex(x, y + 1, z + 1, bid, 3, ao2, flip)
                        local v3 = create_vertex(x, y, z + 1, bid, 3, ao3, flip)

                        if flip == 1 then
                            add_data(v3, v1, v0, v3, v2, v1)
                        else
                            add_data(v0, v2, v1, v0, v3, v2)
                        end
                    end

                    if opaque_fn(back) then
                        local ao0, ao1, ao2, ao3 = self:get_ao(x, y, z - 1, 3)
                        local flip = (ao1 + ao3 > ao0 + ao2) and 1 or 0

                        local v0 = create_vertex(x, y, z, bid, 4, ao0, flip)
                        local v1 = create_vertex(x, y + 1, z, bid, 4, ao1, flip)
                        local v2 = create_vertex(x + 1, y + 1, z, bid, 4, ao2, flip)
                        local v3 = create_vertex(x + 1, y, z, bid, 4, ao3, flip)

                        if flip == 1 then
                            add_data(v3, v0, v1, v3, v1, v2)
                        else
                            add_data(v0, v1, v2, v0, v2, v3)
                        end
                    end

                    if opaque_fn(front) then
                        local ao0, ao1, ao2, ao3 = self:get_ao(x, y, z + 1, 3)
                        local flip = (ao1 + ao3 > ao0 + ao2) and 1 or 0

                        local v0 = create_vertex(x, y, z + 1, bid, 5, ao0, flip)
                        local v1 = create_vertex(x, y + 1, z + 1, bid, 5, ao1, flip)
                        local v2 = create_vertex(x + 1, y + 1, z + 1, bid, 5, ao2, flip)
                        local v3 = create_vertex(x + 1, y, z + 1, bid, 5, ao3, flip)

                        if flip == 1 then
                            add_data(v3, v1, v0, v3, v2, v1)
                        else
                            add_data(v0, v2, v1, v0, v3, v2)
                        end
                    end
                end
            end
        end
    end
end

function Chunk:set_block(bid, x, y, z)
    if x >= 0 and y >= 0 and z >= 0 and x < CHUNK_SIZE and y < CHUNK_SIZE and z < CHUNK_SIZE then
        local i = x + CHUNK_SIZE * z + CHUNK_AREA * y
        self.datapointer[i] = bid
        self:build_mesh()
        return true
    end

    return false
end

function Chunk:get_block(x, y, z)
    if x >= 0 and y >= 0 and z >= 0 and x < CHUNK_SIZE and y < CHUNK_SIZE and z < CHUNK_SIZE then
        local i = x + CHUNK_SIZE * z + CHUNK_AREA * y
        return self.datapointer[i]
    end

    -- se chegar aqui quer dizer que x, y, z está fora desse chunk então a gente pega os vizinhos
    local chunk = self.world:get_chunk(self.x + x, self.y + y, self.z + z)
    if chunk then return chunk:get_block(x % CHUNK_SIZE, y % CHUNK_SIZE, z % CHUNK_SIZE) end
    return -1
end

function Chunk:draw()
    if self.camera:is_on_frustrum(self) then
        
        if self.mesh then
            shader:send("model", "column", self.model_matrix)
            love.graphics.draw(self.mesh)
        end
    end
end

function Chunk:draw_water()
    if self.camera:is_on_frustrum(self) then
        if self.water_mesh then
            love.graphics.draw(self.water_mesh)
        end
    end
end

return Chunk
