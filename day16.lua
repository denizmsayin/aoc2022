local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function mkvalve(name, rate, neighbors)
    return { name = name, rate = rate, neighbors = neighbors }
end


local function parse_valve(line)
    local match_str = '^Valve (%a%a) has flow rate=(%d+); tunnel[s]? lead[s]? to valve[s]? (.*)$'
    local name, rate, neighbors_str = line:match(match_str)
    local neighbors = {}
    for n in neighbors_str:gmatch'(%a%a)' do
        table.insert(neighbors, n)
    end
    return mkvalve(name, tonumber(rate), neighbors)
end

local function read_valves()
    local valves = {}
    for line in io.lines() do
        local valve = parse_valve(line)
        valves[valve.name] = valve
    end
    return valves
end

local function max(a, b)
    return a > b and a or b
end

local function bfs_to_valves(valves, start)
    local q1 = { start }
    local costs = { }
    local cost = 0
    while #q1 > 0 do
        local q2 = {}
        for _, name in ipairs(q1) do
            local v = valves[name]
            for _, neighbor in ipairs(v.neighbors) do
                if costs[neighbor] == nil then
                    table.insert(q2, neighbor)
                    costs[neighbor] = cost + 1
                end
            end
        end
        cost = cost + 1
        q1 = q2
    end
    costs[start] = nil
    for name, _ in pairs(costs) do
        if valves[name].rate == 0 then
            costs[name] = nil
        end
    end
    return costs
end

local function compress_graph(valves, start)
    local compressed = {}
    for name, valve in pairs(valves) do
        if name == start or valve.rate > 0 then
            local cmp_neighbors = bfs_to_valves(valves, name)
            local cvalve = mkvalve(name, valve.rate, cmp_neighbors)
            compressed[name] = cvalve
        end
    end
    return compressed
end

local function print_cgraph(cvalves)
    for name, valve in pairs(cvalves) do
        print(name, valve.rate)
        for n, dist in pairs(valve.neighbors) do
            print(string.format('  %s=%d', n, dist))
        end
    end
end

local function dfs(valves, cur_name, prev_name, mins_left)
    local best = 0

    if mins_left > 0 then
        -- print(cur_name, prev_name)
        local cur_valve = valves[cur_name]
        local rate = cur_valve.rate
        local cand
        if rate > 0 and mins_left > 1 then
            cand = rate * (mins_left - 1)
            cur_valve.rate = 0 -- prevent following search from re-using this valve
            cand = cand + dfs(valves, cur_name, nil, mins_left - 1)
            cur_valve.rate = rate -- restore the rate for further use
            best = max(best, cand)
        end

        for _, n in ipairs(cur_valve.neighbors) do
            if n ~= prev_name then
                cand = dfs(valves, n, cur_name, mins_left - 1)
                best = max(best, cand)
            end
        end
    end

    return best
end

local function dfsc(valves, cur_name, visited, mins_left)
    local best = 0

    if mins_left > 1 then -- can't do anything in just one min
        -- print(cur_name, prev_name)
        local cur_valve = valves[cur_name]
        local rate = cur_valve.rate
        visited[cur_name] = true

        -- Turn on this valve and move on, not doing it is not a choice for compressed graph
        local vented = 0
        if rate > 0 then
            mins_left = mins_left - 1
            vented = rate * mins_left
            best = vented
        end
        for n, cost in pairs(cur_valve.neighbors) do
            if not visited[n] then
                local cand = dfsc(valves, n, visited, mins_left - cost)
                best = max(best, vented + cand)
            end
        end

        visited[cur_name] = false
    end

    return best
end

local valves = read_valves()
local cvalves = compress_graph(valves, 'AA')
-- print_cgraph(cvalves)
print(dfsc(cvalves, 'AA', {}, 30))
-- local r = dfs(valves, 'AA', nil, 30)
-- print(r)
