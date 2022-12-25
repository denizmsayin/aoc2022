local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function max(a, b) return a > b and a or b end

local function cj(t) return table.concat(t, ', ') end

-- For fun, let's attempt to create properties for ore sets!
-- Ore sets are essentially arrays { 0, 0, 0, 0 }, but we also want to support
-- accessing/setting them via keys such as oreset.copper and oreset.clay etc.
-- We'll use the same for RobotSet later too.

-- This is surprisingly simple for index: We simply need to add key - int values to the class 
-- itself. However, for __newindex we do need to write a function that does the rawset

local PATTERN = '%s*Blueprint (%d+):%s+Each ore robot costs (%d+) ore.%s+Each clay robot costs (%d+) ore.%s+Each obsidian robot costs (%d+) ore and (%d+) clay.%s+Each geode robot costs (%d+) ore and (%d+) obsidian.'

local function read_blueprints()
    local bps = {}
    for _, oc, cc, ooc, occ, gorec, gobsc in string.gmatch(io.read('*a'), PATTERN) do
--         print(bid, oc, cc, ooc, occ, gorec, gobsc)
        local bp = { { tonumber(oc), 0, 0 },
                     { tonumber(cc), 0, 0 },
                     { tonumber(ooc), tonumber(occ), 0 },
                     { tonumber(gorec), 0, tonumber(gobsc) } }
        table.insert(bps, bp)
    end
    return bps
end

local function get_blueprint_max_costs(blueprint)
    local max_costs = { 0, 0, 0 }
    for _, costs in ipairs(blueprint) do
        for i = 1, #costs do
            if costs[i] > max_costs[i] then
                max_costs[i] = costs[i]
            end
        end
    end
    return max_costs
end

local function relu(x) return x > 0 and x or 0 end
-- local function relu(x) return x end

local function max_geodes(blueprint, max_t)
    local ore_mcost, clay_mcost, obsi_mcost = compat.unpack(get_blueprint_max_costs(blueprint))
--     print('Max costs:', cj(max_costs))

    local ore_orecost = blueprint[1][1]
    local clay_orecost = blueprint[2][1]
    local obsi_orecost = blueprint[3][1]
    local obsi_claycost = blueprint[3][2]
    local geode_orecost = blueprint[4][1]
    local geode_obsicost = blueprint[4][3]

    local memo = {}

    local function produce(ore_robots, clay_robots, obsi_robots, ore, clay, obsi, t)
        -- At each step, choose the next robot to produce to decide
        -- Try to choose the next robot to make

        -- One key insight for speed: Since only one robot can be produced per time step,
        -- it does not make sense to make more robots for a resource than the max cost with
        -- that resource.

        -- Unrolled from generic implementation for extra speed!!! Ugly though...

        local best = 0

--         local enc = string.format('%d_%d_%d_%d_%d_%d_%d', ore_robots,clay_robots,obsi_robots,ore,clay,obsi,t)
--

        -- Faster than string conversions...
        local enc = (ore_robots + 100 * (clay_robots + 100 * (obsi_robots + 100 *
                        (ore + 100 * (clay + 100 * (obsi + 100 * t))))))

        if memo[enc] ~= nil then
            return memo[enc]
        end

        -- Decision to make ore robot
        if ore_robots < ore_mcost then
            local ttr = math.ceil(relu(ore_orecost - ore) / ore_robots) + 1
            local t_next = t - ttr
            if ttr > 0 and t_next > 0 then
                local p = produce(ore_robots + 1, clay_robots, obsi_robots,
                                  ore + ttr * ore_robots - ore_orecost,
                                  clay + ttr * clay_robots,
                                  obsi + ttr * obsi_robots,
                                  t_next)
                best = max(p, best)
            end
        end

        -- Decision to make clay robot
        if clay_robots < clay_mcost then
            local ttr = math.ceil(relu(clay_orecost - ore) / ore_robots) + 1
            local t_next = t - ttr
            if ttr > 0 and t_next > 0 then
                local p = produce(ore_robots, clay_robots + 1, obsi_robots,
                                  ore + ttr * ore_robots - clay_orecost,
                                  clay + ttr * clay_robots,
                                  obsi + ttr * obsi_robots,
                                  t_next)
                best = max(p, best)
            end
        end

        -- Decision to make obsi robot
        if obsi_robots < obsi_mcost and clay_robots > 0 then
            local to = math.ceil(relu(obsi_orecost - ore) / ore_robots)
            local tc = math.ceil(relu(obsi_claycost - clay) / clay_robots)
            local ttr = max(to, tc) + 1
            local t_next = t - ttr
            if ttr > 0 and t_next > 0  then
                local p = produce(ore_robots, clay_robots, obsi_robots + 1,
                                  ore + ttr * ore_robots - obsi_orecost,
                                  clay + ttr * clay_robots - obsi_claycost,
                                  obsi + ttr * obsi_robots,
                                  t_next)
                best = max(p, best)
            end
        end

        -- And the big one, to make geode robot
        if obsi_robots > 0 then
            local t_ore = math.ceil(relu(geode_orecost - ore) / ore_robots)
            local t_obs = math.ceil(relu(geode_obsicost - obsi) / obsi_robots)
            local ttr = max(t_ore, t_obs) + 1
            local t_next = t - ttr
            if ttr > 0 and t_next > 0 then
                local p = produce(ore_robots, clay_robots, obsi_robots,
                                  ore + ttr * ore_robots - geode_orecost,
                                  clay + ttr * clay_robots,
                                  obsi + ttr * obsi_robots - geode_obsicost,
                                  t_next)
                best = max(p + t_next, best) -- t_next geodes will be produced by this robot!
            end
        end

        memo[enc] = best
        return best
    end
        -- 

    return produce(1, 0, 0, 0, 0, 0, max_t)
end


local blueprints = read_blueprints()
if utils.IS_PART_1 then
    local quality = 0
    for i = 1, #blueprints do
        quality = quality + i * max_geodes(blueprints[i], 24)
    end
    print(quality)
else
    local prod = 1
    for i = 1, 3 do
        local p = max_geodes(blueprints[i], 32)
        prod = prod * p
    end
    print(prod)
end
