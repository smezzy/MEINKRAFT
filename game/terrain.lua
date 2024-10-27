BIOME = {
    WATER = 1,
    BEACH = 2,
    FOREST = 3,
    TESTE = 4,
}

local WATER_ID = 9
local DIRT_ID = 2
local GRASS_ID = 1
local SAND_ID = 4
local WOOD_ID = 6
local OAK_ID = 7
local LEAVES_ID = 8
local STONE_ID = 10
local COBBLESTONE_ID = 3

local TerrainGen = Class:extend()

function TerrainGen:init(seed)
    self.seed = seed or os.time()
    self.water_level = 62
end

function TerrainGen:get_elevation(x, z)
    local fudge_factor = 1
    local a1 = 1 -- amplitude
    local a2, a4, a8 = a1 * 0.5, a1 * 0.25, a1 * 0.125

    local f1 = 0.005 -- frequency
    local f2, f4, f8 = f1 * 2, f1 * 4, f1 * 8

    local e =   love.math.noise(x * f1, z * f1) * a1
                   + love.math.noise(x * f2, z * f2) * a2
                   + love.math.noise(x * f4, z * f4) * a4
                   + love.math.noise(x * f8, z * f8) * a8

    e = e / (a1 + a2 + a4 + a8)


    e = math.pow(e * fudge_factor, 0.8)

    return e
end

function TerrainGen:get_moist(x, z)
    local fudge_factor = 1
    local a1 = 1 -- amplitude
    local a2, a4, a8 = a1 * 0.5, a1 * 0.25, a1 * 0.125

    local f1 = 0.005 -- frequency
    local f2, f4, f8 = f1 * 2, f1 * 4, f1 * 8

    local moist =   love.math.noise(x * f1 + 12, z * f1 + 12) * a1
                   + love.math.noise(x * f2 - 3, z * f2- 3) * a2
                   + love.math.noise(x * f4 - 32, z * f4 - 32) * a4
                   + love.math.noise(x * f8 + 128, z * f8 + 128) * a8

    moist = moist / (a1 + a2 + a4 + a8)

    moist = math.pow(moist * fudge_factor, 2)

    return moist
end

function TerrainGen:place_tree(x, y, z)
    world:set_block(OAK_ID, x, y, z)
    world:set_block(OAK_ID, x, y+1, z)
    world:set_block(OAK_ID, x, y+2, z)
    world:set_block(OAK_ID, x, y+3, z)
    world:set_block(OAK_ID, x, y+5, z)
    for tx = -2, 2 do
        for tz = -2, 2 do
            world:set_block(LEAVES_ID, x + tx, y + 5, z + tz)
        end
    end
    
    world:set_block(OAK_ID, x, y+6, z)
    for tx = -2, 2 do
        for tz = -2, 2 do
            world:set_block(LEAVES_ID, x + tx, y + 6, z + tz)
        end
    end

    for tx = -1, 1 do
        world:set_block(LEAVES_ID, x + tx, y + 7, z)
    end
    
    for tz = -1, 1 do
        world:set_block(LEAVES_ID, x, y + 7, z + tz)
    end
end

function TerrainGen:get_biome(e, m)
    if e < 0.6 then return BIOME.WATER end

    if e < 0.62 then return BIOME.BEACH end

    if e >= 0.62 then
        if (m < 0.65) then
            return BIOME.FOREST
        else
            return BIOME.TESTE
        end
    end

    return BIOME.FOREST
end


return TerrainGen