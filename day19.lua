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

local function read_blueprints(nmax)
    if nmax == nil then nmax = 1000 end
    local bps = {}
    for _, oc, cc, ooc, occ, gorec, gobsc in string.gmatch(io.read('*a'), PATTERN) do
--         print(bid, oc, cc, ooc, occ, gorec, gobsc)
        local bp = { { tonumber(oc), 0, 0 },
                     { tonumber(cc), 0, 0 },
                     { tonumber(ooc), tonumber(occ), 0 },
                     { tonumber(gorec), 0, tonumber(gobsc) } }
        table.insert(bps, bp)
        if #bps >= nmax then
            break
        end
    end
    return bps
end
-- 
-- local function copy4(arr)
--     return { arr[1], arr[2], arr[3], arr[4] }
-- end
-- 
-- local function enough_ores_for(robot_cost, ores)
--     for i = 1, #robot_cost do
--         if robot_cost[i] > ores[i] then
--             return false
--         end
--     end
--     return true
-- end
-- 
-- local function build_robot(bp, i, robots, ores)
--     ores = copy4(ores)
--     robots = copy4(robots)
--     local robot_cost = bp[i]
--     for j = 1, #robot_cost do
--         ores[j] = ores[j] - robot_cost[j]
--     end
--     robots[i] = robots[i] + 1
--     return robots, ores
-- end
-- 
-- local memo_table = {}
-- 
-- local function make_key(robots, ores, t)
--     return string.format('%d_%d_%d_%d_%d_%d_%d_%d', robots[1], robots[2], robots[3], robots[4],
--                          ores[1], ores[2], ores[3], t)
-- end
-- 
-- local function max_ore_cost(bp)
--     local m = 0
--     for _, cost in pairs(bp) do
--         if cost[1] > m then
--             m = cost[1]
--         end
--     end
--     return m
-- end
-- 
-- -- local function produce(blueprint, robots, ores, t, moc)
-- --     if t <= 0 then
-- --         return ores[4]
-- --     end
-- -- 
-- --     local best = ores[4]
-- --     local cand
-- --     local produced = false
-- --     -- Try producing stuff
-- --     for i = 1, #blueprint do
-- --         if enough_ores_for(blueprint[i], ores) then
-- --             local srobots, sores = build_robot(blueprint, i, robots, ores)
-- --             produced = true
-- --             sores = mine_ores(robots, sores)
-- --             cand = produce(blueprint, srobots, sores, t - 1, moc)
-- --             if cand > best then
-- --                 best = cand
-- --             end
-- --         end
-- --     end
-- --     -- Try not producing if nothing could be produced, or if there's less ore than max
-- --     if not produced or ores[1] < moc then
-- --         cand = produce(blueprint, robots, mine_ores(robots, ores), t - 1, moc)
-- --         if cand > best then
-- --             best = cand
-- --         end
-- --     end
-- --     return best
-- -- end

local function cparr(arr)
    local cp = {}
    for i = 1, #arr do
        cp[i] = arr[i]
    end
    return cp
end

-- Generic function for checking whether the current robot set
-- can produce the target robot after waiting a while
local function can_build_robot(blueprint, robots, robot)
    local cost = blueprint[robot]
    for i = 1, #cost do
        if cost[i] > 0 and robots[i] == 0 then
            return false
        end
    end
    return true
end

-- Assuming the robot can be build, how many steps would we need to wait to build it?
local function time_to_robot(blueprint, robots, minerals, robot)
    local cost = blueprint[robot]
    local max_t = 0 -- zero return implies can't produce
    for i = 1, #cost do
        if cost[i] > 0 then
            if robots[i] > 0 then
                local t = math.ceil((cost[i] - minerals[i]) / robots[i])
                max_t = max(max_t, t)
            else -- cost exists, but no robot to mine the necessary mineral
                return 0
            end
        end
    end
    return max_t + 1 -- because production takes one extra turn
end

local function mine_minerals_build_robot(blueprint, robots, minerals, robot, t)
    local cost = blueprint[robot]
    minerals = cparr(minerals)
    for i = 1, #cost do
        minerals[i] = minerals[i] + robots[i] * t - cost[i]
        if minerals[i] < 0 then
            print(cj(minerals), cj(robots), cj(cost))
            error('Oopsie')
        end
    end
    robots = cparr(robots)
    robots[robot] = robots[robot] + 1
    return minerals, robots
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

local function max_geodes(blueprint, max_t)
    local ore_mcost, clay_mcost, obsi_mcost = compat.unpack(get_blueprint_max_costs(blueprint))
--     print('Max costs:', cj(max_costs))

    local ore_orecost = blueprint[1][1]
    local clay_orecost = blueprint[2][1]
    local obsi_orecost = blueprint[3][1]
    local obsi_claycost = blueprint[3][2]
    local geode_orecost = blueprint[4][1]
    local geode_obsicost = blueprint[4][3]

    local function produce(ore_robots, clay_robots, obsi_robots, ore, clay, obsi, t)
        if t <= 0 then
            return 0
        end

        -- At each step, choose the next robot to produce to decide
        -- Try to choose the next robot to make

        -- One key insight for speed: Since only one robot can be produced per time step,
        -- it does not make sense to make more robots for a resource than the max cost with
        -- that resource.

        -- Unrolled from generic implementation for extra speed!!! Ugly though...

        local best = 0

        -- Decision to make ore robot
        if ore_robots < ore_mcost then
            local ttr = math.ceil((ore_orecost - ore) / ore_robots) + 1
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
            local ttr = math.ceil((clay_orecost - ore) / ore_robots) + 1
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
            local to = math.ceil((obsi_orecost - ore) / ore_robots)
            local tc = math.ceil((obsi_claycost - clay) / clay_robots)
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
            local t_ore = math.ceil((geode_orecost - ore) / ore_robots)
            local t_obs = math.ceil((geode_obsicost - obsi) / obsi_robots)
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

        return best
    end
        -- 

    return produce(1, 0, 0, 0, 0, 0, max_t)
end

local nmax, time
if utils.IS_PART_1 then
    time = 24
else
    nmax, time = 3, 32
end

local blueprints = read_blueprints(nmax)
local quality = 0
for i = 1, #blueprints do
    local bp = blueprints[i]
--     print('Blueprint:', i)
--     for _, cost in ipairs(bp) do
--         print(table.concat(cost, ', '))
--     end
    local p = max_geodes(bp, time)
--     print(p)
    quality = quality + i * p
end
-- for k, v in pairs(choices) do
--     print(k, table.concat(v, ' -> '), cj(v.ores))
-- end
print(quality)
