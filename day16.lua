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

local valves = read_valves()
local r = dfs(valves, 'AA', nil, 30)
print(r)
