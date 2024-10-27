local Scene = Class:extend()

function Scene:init()
    self.camera = require("game.camera")()
    
    self.world = require("game.world")(self)
    self.world:build_chunks()
    self.world:build_chunk_mesh()
    
    self.player = require("game.player")(self, MAX_HEIGHT/2, 8 *CHUNK_SIZE)
end

function Scene:update(dt)
    self.world:update(dt)
    self.player:update(dt)
    self.camera:update(dt)
end

function Scene:draw()
    self.world:draw()
    self.player.marker:draw()
end

return Scene