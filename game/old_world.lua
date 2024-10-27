-- local Chunk = require("game.chunk")

-- local function chunk_hash(x, z)
--     return x * 73856093 + z * 83492791
-- end

-- ---@class World : Class
-- ---@overload fun(): World
-- local world = Class:extend()

-- function world:init()
--     self.chunk_hash_table = {}
-- end

-- local function round(x)
--     return math.floor(x + 0.5)
-- end

-- local remesh_queue = {}
-- local cx, cz = 0, 0

-- function world:update(dt)
--     local px, pz = camera.position.x, camera.position.z

--     px, pz = math.floor(px / CHUNK_SIZE), math.floor(pz / CHUNK_SIZE)
--     -- px, pz = 0, 0
--     local rd = math.floor(RENDER_DISTANCE / 2)

--     for x = -rd, rd do
--         for z = -rd, rd do
--             local chunk = self:get_chunk(px + x, pz + z)
--             if not chunk then
--                 chunk = self:create_chunk(px + x, pz + z)

--                 chunk.dirty = true
--                 table.insert(remesh_queue, chunk)

--                 local neighbors = self:get_neighbors(px + x, pz + z)
--                 for _, n in ipairs(neighbors) do
--                     n.dirty = true
--                     table.insert(remesh_queue, n)
--                 end
--             end
--         end
--     end

--     -- for x = -rd, rd do
--     --     for z = -rd, rd do
--     --         local chunk = self:get_chunk(px + x, pz + z)
--     --         if chunk and chunk.dirty then
--     --             chunk.dirty = false
--     --             chunk:update_mesh()
--     --         end
--     --     end
--     -- end

--     for i = #remesh_queue, 1, -1 do
--         local c = remesh_queue[i]
--         c.dirty = false
--         c:update_mesh()
--         table.remove(remesh_queue, i)
--     end
-- end


-- -- function World:check(hit_callback, current_block, next_block)
-- --     local block = self:get_block(current_block.x, current_block.y, current_block.z)
-- --     if block then
-- --         hit_callback(current_block, next_block)
-- --     end
-- --     return block ~= nil
-- -- end

-- local sqrt, pow = math.sqrt, math.pow
-- ---@param start Vec3
-- ---@param direction Vec3
-- function world:ray_intersect(start, direction)
--     local ray_start = start:clone()
--     local ray_dir = direction:normalize()
--     local dx, dy, dz = ray_dir:unpack()
--     local ray_step = vec3(
--         sqrt(1 + (dy / dx) ^ 2 + (dz / dx) ^ 2),
--         sqrt(1 + (dx / dy) ^ 2 + (dz / dy) ^ 2),
--         sqrt(1 + (dx / dz) ^ 2 + (dy / dz) ^ 2)
--     )
--     local block_pos = ray_start:truncate()
--     local ray_length = vec3()
--     local step = vec3()

--     if ray_dir.x < 0 then
--         step.x = -1
--         ray_length.x = (ray_start.x - block_pos.x) * ray_step.x
--     else
--         step.x = 1
--         ray_length.x = (block_pos.x - ray_start.x) * ray_step.x
--     end

--     if ray_dir.y < 0 then
--         step.y = -1
--         ray_length.y = (ray_start.y - block_pos.y) * ray_step.y
--     else
--         step.y = 1
--         ray_length.y = (block_pos.y - ray_start.y) * ray_step.y
--     end

--     if ray_dir.z < 0 then
--         step.z = -1
--         ray_length.z = (ray_start.z - block_pos.z) * ray_step.z
--     else
--         step.z = 1
--         ray_length.z = (block_pos.z - ray_start.z) * ray_step.z
--     end

--     local map = { 'x', 'y', 'z' }
--     local function min_component(v)
--         local min = v[map[1]]
--         local idx = 1
--         for i = 1, 3 do
--             if v[map[i]] < min then
--                 min = v[map[i]]
--                 idx = i
--             end
--         end
--         return idx
--     end

--     local total_distance = 0
--     local block_found = false
--     local face = nil
--     while total_distance < HIT_RANGE and not block_found do
--         local min_idx = min_component(ray_length)
--         face = map[min_idx]
--         block_pos[map[min_idx]] = block_pos[map[min_idx]] + step[map[min_idx]]
--         total_distance = ray_length[map[min_idx]]
--         ray_length[map[min_idx]] = ray_length[map[min_idx]] + ray_step[map[min_idx]]
--         local block = self:get_block(block_pos:unpack())
--         if block then block_found = true end
--     end


--     local intersection = ray_start + ray_dir * total_distance
--     if block_found then
--         local hit_block_pos = block_pos
--         local place_block_pos = block_pos:clone()

--         -- Adjust place_block_pos based on the intersected face
--         if face == 'x' then
--             place_block_pos.x = place_block_pos.x - step.x
--         elseif face == 'y' then
--             place_block_pos.y = place_block_pos.y - step.y
--         elseif face == 'z' then
--             place_block_pos.z = place_block_pos.z - step.z
--         end

--         return intersection, hit_block_pos, place_block_pos
--     else
--         return nil
--     end

--     -- local intersection = start + ray_dir * total_distance
--     -- return block_found and intersection or nil
-- end

-- function world:hit()
--     local position = camera.position:clone()
--     local block = (camera.position + vec3(.5, .5, .5)):truncate()
--     local distance = 0

--     while distance < HIT_RANGE do
--         local localPos = position - block
--         local absolute = (camera.forward):clone()
--         local sign = vec3(1, 1, 1)

--         if absolute.x < 0 then
--             absolute.x = -absolute.x
--             localPos.x = -localPos.x
--             sign.x = -1
--         end

--         if absolute.y < 0 then
--             absolute.y = -absolute.y
--             localPos.y = -localPos.y
--             sign.y = -1
--         end

--         if absolute.z < 0 then
--             absolute.z = -absolute.z
--             localPos.z = -localPos.z
--             sign.z = -1
--         end

--         local lx, ly, lz = localPos:unpack()
--         local vx, vy, vz = absolute:unpack()

--         if vx > 0 then
--             local x = 0.5
--             local y = (0.5 - lx) / vx * vy + ly
--             local z = (0.5 - lx) / vx * vz + lz

--             if y >= -0.5 and y <= 0.5 and z >= -0.5 and z <= 0.5 then
--                 local dist = (vec3(x, y, z) - vec3(lx, ly, lz)):len()
--                 local nextBlock = block + vec3(sign.x, 0, 0)

--                 if self:get_block(nextBlock:unpack()) ~= nil then
--                     return block, nextBlock
--                 else
--                     position = position + camera.forward * distance
--                     block = nextBlock
--                     distance = distance + dist
--                 end
--             end
--         end

--         if vy > 0 then
--             local x = (0.5 - ly) / vy * vx + lx
--             local y = 0.5
--             local z = (0.5 - ly) / vy * vz + lz

--             if x >= -0.5 and x <= 0.5 and z >= -0.5 and z <= 0.5 then
--                 local dist = (vec3(x, y, z) - vec3(lx, ly, lz)):len()
--                 local nextBlock = block + vec3(0, sign.y, 0)

--                 if self:get_block(nextBlock:unpack()) ~= nil then
--                     return block, nextBlock
--                 else
--                     position = position + camera.forward * distance
--                     block = nextBlock
--                     distance = distance + dist
--                 end
--             end
--         end

--         if vz > 0 then
--             local x = (0.5 - lz) / vz * vx + lx
--             local y = (0.5 - lz) / vz * vy + ly
--             local z = 0.5

--             if x >= -0.5 and x <= 0.5 and y >= -0.5 and y <= 0.5 then
--                 local dist = (vec3(x, y, z) - vec3(lx, ly, lz)):len()
--                 local nextBlock = block + vec3(0, 0, sign.z)

--                 if self:get_block(nextBlock:unpack()) ~= nil then
--                     return block, nextBlock
--                 else
--                     position = position + camera.forward * distance
--                     block = nextBlock
--                     distance = distance + dist
--                 end
--             end
--         end
--     end

--     return nil
-- end

-- function world:get_neighbors(cx, cz)
--     local neighbors = {}

--     table.insert(neighbors, self:get_chunk(cx + 1, cz))
--     table.insert(neighbors, self:get_chunk(cx - 1, cz))
--     table.insert(neighbors, self:get_chunk(cx, cz + 1))
--     table.insert(neighbors, self:get_chunk(cx, cz - 1))
--     return neighbors
-- end

-- function world:set_block(block_id, x, y, z)
--     local cx = math.floor(x / CHUNK_SIZE)
--     local cz = math.floor(z / CHUNK_SIZE)
--     local chunk = self:get_chunk(cx, cz)

--     if not chunk then return end

--     local cw, ch, cl = CHUNK_SIZE, CHUNK_HEIGHT, CHUNK_SIZE
--     local lx, ly, lz = math.floor(x % cw), math.floor(y % ch), math.floor(z % cl)

--     if y <= 0 or y >= CHUNK_HEIGHT then return end



--     if chunk.blocks[lx + 1][ly + 1][lz + 1] == block_id then return end

--     chunk.blocks[lx + 1][ly + 1][lz + 1] = block_id

--     chunk:update_mesh()

--     if lx == cw - 1 then
--         local c = self:get_chunk(cx + 1, cz)
--         c:update_mesh()
--     elseif lx == 0 then
--         local c = self:get_chunk(cx - 1, cz)
--         c:update_mesh()
--     end

--     if lz == cl - 1 then
--         local c = self:get_chunk(cx, cz + 1)
--         c:update_mesh()
--     elseif lz == 0 then
--         local c = self:get_chunk(cx, cz - 1)
--         c:update_mesh()
--     end
--     print("colocando bloco")
-- end

-- function world:create_chunk(x, z)
--     local chunk = Chunk(self, x, z)
--     chunk:generate()
--     self.chunk_hash_table[chunk_hash(x, z)] = chunk
--     return chunk
-- end

-- function world:get_chunk(x, z)
--     local chunk = self.chunk_hash_table[chunk_hash(x, z)]
--     return chunk
-- end

-- function world:get_block(x, y, z)
--     local cx = math.floor(x / CHUNK_SIZE)
--     local cz = math.floor(z / CHUNK_SIZE)
--     local chunk = self:get_chunk(cx, cz)

--     if not chunk then return nil end

--     if y >= CHUNK_HEIGHT or y <= 0 then
--         return nil
--     end

--     local cw, ch, cl = CHUNK_SIZE, CHUNK_HEIGHT, CHUNK_SIZE
--     local lx, ly, lz = math.floor(x % cw), math.floor(y % ch), math.floor(z % cl)


--     local block_id = chunk.blocks[lx + (ly * CHUNK_SIZE) + (lz * CHUNK_SIZE * CHUNK_HEIGHT) + 1]
--     return block_list[block_id], x, y, z
-- end

-- function world:draw()
--     local model = mat4()

--     local px, pz = camera.position.x, camera.position.z
--     px, pz = math.floor(px / CHUNK_SIZE), math.floor(pz / CHUNK_SIZE)

--     local rd = math.floor(RENDER_DISTANCE / 2)
--     for x = -rd, rd do
--         for z = -rd, rd do
--             local chunk = self:get_chunk(px + x, pz + z)
--             if chunk then
--                 mat4.translate(model, mat4(), vec3(chunk.x, 0, chunk.z))
--                 shader:send("model", "column", model)
--                 chunk:draw()
--             end
--         end
--     end
-- end

-- return world
