local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function mkvalve(name, rate, neighbors)
    return { name = name, rate = rate, neighbors = neighbors }
end

local function shallow_copy(t)
    local u = {}
    for k, v in pairs(t) do
        u[k] = v
    end
    return u
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

-- Convert graph to use int keys
local function create_name_to_index_mapping(valves)
    local t = {}
    local i = 1
    for name, _ in pairs(valves) do
        t[name] = i
        i = i + 1
    end
    return t
end

local function to_integer_keys(valves, lookup)
    local ivalves = {}
    for name, valve in pairs(valves) do
        valve = shallow_copy(valve)
        local ineighbors = {}
        for nname, dist in pairs(valve.neighbors) do
            ineighbors[lookup[nname]] = dist
        end
        valve.neighbors = ineighbors
        ivalves[lookup[name]] = valve
    end
    return ivalves
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
    local lookup = create_name_to_index_mapping(compressed)
    return to_integer_keys(compressed, lookup), lookup
end

local function print_cgraph(cvalves)
    for _, valve in ipairs(cvalves) do
        print(valve.name, valve.rate)
        for i, dist in pairs(valve.neighbors) do
            print(string.format('  %d=%d', i, dist))
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

local function dfsc(valves, cur_ind, visited, mins_left)
    local best = 0

    if mins_left > 1 then -- can't do anything in just one min
        -- print(cur_ind, prev_name)
        local cur_valve = valves[cur_ind]
        local rate = cur_valve.rate
        visited[cur_ind] = true

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

        visited[cur_ind] = false
    end

    return best
end

local function dfsc2(start_ind, start_mins, valves, cur_ind, visited, mins_left)
    if mins_left > 1 then -- can't do anything in just one min
        -- print(cur_ind, prev_name)
        local best = 0
        local cur_valve = valves[cur_ind]
        local rate = cur_valve.rate
        visited[cur_ind] = true

        -- Turn on this valve and move on, not doing it is not a choice for compressed graph
        local vented = 0
        if rate > 0 then
            mins_left = mins_left - 1
            vented = rate * mins_left
            best = vented
        end
        for n, cost in pairs(cur_valve.neighbors) do
            if not visited[n] then
                local cand = dfsc2(start_ind, start_mins, valves, n, visited, mins_left - cost)
                best = max(best, vented + cand)
            end
        end

        visited[cur_ind] = false

        -- Also, attempt to have other elephant bro do everything instead
        local cand = dfsc(valves, start_ind, visited, start_mins)
        best = max(best, cand)

        return best
    else
        return dfsc(valves, start_ind, visited, start_mins)
    end
end
-- 
-- local function dfsc2(valves, visited, my_state, other_state)
--     if my_state.mins_left <= 1 and other_state.mins_left <= 1 then
--         return 0
--     elseif my_state.mins_left <= 1 then
--         return dfsc2(valves, visited, other_state, my_state)
--     else
--         local best = 0
--         local mins_left = my_state.mins_left
--         local cur_name = my_state.cur_name
--         -- print(cur_name, prev_name)
--         local cur_valve = valves[cur_name]
--         local rate = cur_valve.rate
-- 
--         -- Turn on this valve and move on, not doing it is not a choice for compressed graph
--         local vented = 0
--         if rate > 0 then
--             mins_left = mins_left - 1
--             vented = rate * mins_left
-- --             print(string.format('%p: Opened %s, vented %d', my_state, cur_name, vented))
--             best = vented
--         end
--         for n, cost in pairs(cur_valve.neighbors) do
--             if not visited[n] then
--                 visited[n] = true
--                 my_state.cur_name, my_state.mins_left = n, mins_left - cost
--                 local cand = dfsc2(valves, visited, other_state, my_state)
--                 my_state.cur_name, my_state.mins_left = cur_name, mins_left -- restore mins left to continue search
--                 best = max(best, vented + cand)
--                 visited[n] = false
--             end
--         end
-- 
--         return best
--     end
-- end

local START_NODE = 'AA'
local valves = read_valves()
local cvalves, name_mapping = compress_graph(valves, START_NODE)
local start_ind = name_mapping[START_NODE]
-- print_cgraph(cvalves)
if utils.IS_PART_1 then
    print(dfsc(cvalves, start_ind, {}, 30))
else
    print(dfsc2(start_ind, 26, cvalves, start_ind, {}, 26))
end
