local cube = require("models").cube

--- [block_id] = block_name, model, textures[sides, top, bottom]
return {
    [1] = { "Grass Block" , cube  , {"grass_side", "grass_top", "dirt"} },
    [2] = { "Dirt"        , cube  , {"dirt"} },
    [3] = { "Cobblestone" , cube  , {"cobblestone"} },
    [4] = { "Sand"        , cube  , {"sand"} },
    [5] = { "Glass Block" , cube  , {"glass"} },
    [6] = { "Wood Plank"  , cube  , {"planks_oak"} },
    [7] = { "Oak Log"     , cube  , {"log_oak_top", "log_oak_top", "log_oak_top"} },
    [8] = { "Oak Leaves"  , cube  , {"leaves_oak"} },
    [9] = { "Water Block" , cube  , {"water"} },
    [10] = { "Stone"      , cube  , {"stone"} },
    [11] = { "Mycelium"   , cube  , {"mycelium_side", "dirt"} },
}
