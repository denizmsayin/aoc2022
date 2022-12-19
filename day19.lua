local utils = require 'lib/utils'
local compat = require 'lib/compat'

local PATTERN = '%s*Blueprint (%d+):%s+Each ore robot costs (%d+) ore.%s+Each clay robot costs (%d+) ore.%s+Each obsidian robot costs (%d+) ore and (%d+) clay.%s+Each geode robot costs (%d+) ore and (%d+) obsidian.'

local function read_blueprints()
    local bps = {}
    for bid, oc, cc, ooc, occ, gorec, gobsc in string.gmatch(io.read('*a'), PATTERN) do
--         print(bid, oc, cc, ooc, occ, gorec, gobsc)
        local bp = { { tonumber(oc), 0, 0 },
                     { tonumber(cc), 0, 0 },
                     { tonumber(ooc), tonumber(occ), 0 },
                     { tonumber(gorec), 0, tonumber(gobsc) } }
        table.insert(bps, bp)
    end
    return bps
end

local function copy4(arr)
    return { arr[1], arr[2], arr[3], arr[4] }
end

local function enough_ores_for(robot_cost, ores)
    for i = 1, #robot_cost do
        if robot_cost[i] > ores[i] then
            return false
        end
    end
    return true
end

local function build_robot(bp, i, robots, ores)
    ores = copy4(ores)
    robots = copy4(robots)
    local robot_cost = bp[i]
    for j = 1, #robot_cost do
        ores[j] = ores[j] - robot_cost[j]
    end
    robots[i] = robots[i] + 1
    return robots, ores
end

local function mine_ores(robots, ores)
    ores = copy4(ores)
    for i = 1, #robots do
        ores[i] = ores[i] + robots[i]
    end
    return ores
end

local memo_table = {}

local function make_key(robots, ores, t)
    return string.format('%d_%d_%d_%d_%d_%d_%d_%d', robots[1], robots[2], robots[3], robots[4],
                         ores[1], ores[2], ores[3], t)
end

local function max_ore_cost(bp)
    local m = 0
    for _, cost in pairs(bp) do
        if cost[1] > m then
            m = cost[1]
        end
    end
    return m
end

local function produce(blueprint, robots, ores, t, moc)
    if t <= 0 then
        return ores[4]
    end

    local k = make_key(robots, ores, t)
    if memo_table[k] == nil then
        local best = ores[4]
        local cand
        local produced = false
        -- Try producing stuff
        for i = 1, #blueprint do
            if enough_ores_for(blueprint[i], ores) then
                local srobots, sores = build_robot(blueprint, i, robots, ores)
                produced = true
                sores = mine_ores(robots, sores)
                cand = produce(blueprint, srobots, sores, t - 1, moc)
                if cand > best then
                    best = cand
                end
            end
        end
        -- Try not producing if nothing could be produced, or if there's less ore than max
        if not produced or ores[1] < moc then
            cand = produce(blueprint, robots, mine_ores(robots, ores), t - 1, moc)
            if cand > best then
                best = cand
            end
        end
        memo_table[k] = best
    end
    return memo_table[k]
end

local blueprints = read_blueprints()
local quality = 0
for i = 1, #blueprints do
    local bp = blueprints[i]
    for _, cost in ipairs(bp) do
        print(table.concat(cost, ', '))
    end
    memo_table = {}
    local p = produce(bp, { 1, 0, 0, 0 }, { 0, 0, 0, 0 }, 24, max_ore_cost(bp))
    print(p)
    quality = quality + i * p
end
print(quality)
