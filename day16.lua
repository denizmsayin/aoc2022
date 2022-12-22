local utils = require 'lib/utils'
local compat = require 'lib/compat'


local START_NODE = 'AA'

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

local function encode_state(num_nodes, cur_ind, visited, mins_left)
    local v = 0
    for i = 1, num_nodes do -- encode visited
        local c = visited[i] and 1 or 0
        v = 2 * v + c
    end
    v = v * (num_nodes + 1) + cur_ind
    v = v * 50 + mins_left
    return v
end

local function decode_state(num_nodes, enc)
    local mins_left = enc % 50
    enc = (enc - mins_left) / 50
    local cur_ind = enc % (num_nodes + 1)
    enc = (enc - cur_ind) / (num_nodes + 1)
    local visited = {}
    for i = num_nodes, 1, -1 do
        local c = enc % 2
        if c == 1 then
            visited[i] = true
        end
        enc = (enc - c) / 2
    end
    if enc ~= 0 then error('Decoding logic error') end
    return cur_ind, visited, mins_left
end

local function visited2str(visited)
    local s = ''
    for i, v in pairs(visited) do
        if v then
            s = s .. tostring(i)
        end
    end
    return s
end

local function dfs(valves, lookup, max_mins, double_search)
    -- The recursive closure here uses the constant arguments from above
    local start_ind = lookup['AA']
    local function dfs_(cur_ind, visited, mins_left, is_elephant)
        local best = 0

        if not is_elephant then
            local cand = dfs_(start_ind, visited, max_mins, true)
            best = max(best, cand)
        end

        if mins_left <= 1 then
            return best
        end

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
                local cand = dfs_(n, visited, mins_left - cost, is_elephant)
                best = max(best, vented + cand)
            end
        end

        visited[cur_ind] = false

        return best
    end
    return dfs_(start_ind, {}, max_mins, not double_search)
end

local valves = read_valves()
local cvalves, name_mapping = compress_graph(valves, START_NODE)
-- print_cgraph(cvalves)
if utils.IS_PART_1 then
    print(dfs(cvalves, name_mapping, 30, false))
else
    print(dfs(cvalves, name_mapping, 26, true))
end
