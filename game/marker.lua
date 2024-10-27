local vertex_format = {
    {"VertexPosition", "float", 3},
    {"TextureCoords", "float", 3},
}

local models = {
    cube = {
        vertex_positions = {
           { 0.5,  0.5,  0.5}, { 0.5, -0.5,  0.5}, { 0.5, -0.5, -0.5},  {0.5,  0.5, -0.5},
           {-0.5,  0.5, -0.5}, {-0.5, -0.5, -0.5}, {-0.5, -0.5,  0.5},  {-0.5,  0.5,  0.5},
           {-0.5,  0.5,  0.5}, {-0.5,  0.5, -0.5}, { 0.5,  0.5, -0.5},  {0.5,  0.5,  0.5},
           {-0.5, -0.5,  0.5}, {-0.5, -0.5, -0.5}, { 0.5, -0.5, -0.5},  {0.5, -0.5,  0.5},
           {-0.5,  0.5,  0.5}, {-0.5, -0.5,  0.5}, { 0.5, -0.5,  0.5},  {0.5,  0.5,  0.5},
           { 0.5,  0.5, -0.5}, { 0.5, -0.5, -0.5}, {-0.5, -0.5, -0.5},  {-0.5,  0.5, -0.5},
       },
       
       tex_coords = {
           {0.0, 1.0, 0.0}, {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {1.0, 1.0, 0.0},
           {0.0, 1.0, 0.0}, {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {1.0, 1.0, 0.0},
           {0.0, 1.0, 0.0}, {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {1.0, 1.0, 0.0},
           {0.0, 1.0, 0.0}, {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {1.0, 1.0, 0.0},
           {0.0, 1.0, 0.0}, {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {1.0, 1.0, 0.0},
           {0.0, 1.0, 0.0}, {0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {1.0, 1.0, 0.0},
       },
       
       indices = {
            1,  2,  3,  1,  3,  4, -- right
            5,  6,  7,  5,  7,  8, -- left
            9,  12, 11,  9, 11, 10, -- top
           13, 14, 15, 13, 15, 16, -- bottom
           17, 18, 19, 17, 19, 20, -- front
           21, 22, 23, 21, 23, 24 -- back
       }
    }
}

---@class Marker : Class
---@overload fun(): Marker
local Marker = Class:extend()
function Marker:init(camera)
    local vertex_list = {}
    for v = 1, #models.cube.vertex_positions do
        local vertex = {}
        table.insert(vertex, models.cube.vertex_positions[v][1])
        table.insert(vertex, models.cube.vertex_positions[v][2])
        table.insert(vertex, models.cube.vertex_positions[v][3])
        
        table.insert(vertex, models.cube.tex_coords[v][1])
        table.insert(vertex, models.cube.tex_coords[v][2])
        table.insert(vertex, models.cube.tex_coords[v][3])
        table.insert(vertex_list, vertex)
    end
    self.mesh = love.graphics.newMesh(vertex_format, vertex_list, "triangles", "static")
    self.mesh:setVertexMap(models.cube.indices)
    
    self.shader = love.graphics.newShader("assets/shaders/marker.glsl")
    self.texture = love.graphics.newImage("assets/textures/marker.png")
    
    self.camera = camera
    self.model_matrix = mat4()
    self.position = vec3(0)
    self.visible = false
    self.px, self.py, self.pz = 0, 0, 0
end

function Marker:update_position(bid, x, y, z)
    if bid == 0 then 
        self.visible = false 
    else
        self.visible = true
        if self.position.x ~= self.px or self.position.y ~= self.py or self.position.z ~= self.pz then
            self.position.x = x
            self.position.y = y
            self.position.z = z
            mat4.translate(self.model_matrix, mat4(), self.position)
        end
    end
    self.px, self.py, self.pz = x, y, z
end

function Marker:draw()
    if not self.visible then return end
    local previous = love.graphics.getShader()
    love.graphics.setShader(self.shader)
    love.graphics.setWireframe(true)
    self.shader:send("marker_texture", self.texture)
    self.shader:send("projection", "column", self.camera.projection)
    self.shader:send("view", "column", self.camera.view_matrix)
    self.shader:send("model", "column", self.model_matrix)
    love.graphics.draw(self.mesh)
    love.graphics.setWireframe(false)
    love.graphics.setShader(previous)
end

return Marker