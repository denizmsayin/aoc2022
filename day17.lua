local utils = require 'lib/utils'
local compat = require 'lib/compat'


local function read_jets()
    local l = io.read()
    local t = {}
    for i = 1, #l do
        t[i] = l:sub(i, i) == '>' and 1 or -1
    end
    return t
end

local function max(a, b) return a > b and a or b end

local function maximum(t)
    local m = t[1]
    for i = 2, #t do
        if t[i] > m then
            m = t[i]
        end
    end
    return m
end

local function make_grid(h, w, v)
    local t = {}
    for _ = 1, h do
        local r = {}
        for _ = 1, w do
            table.insert(r, v)
        end
        table.insert(t, r)
    end
    return t
end

local function make_rock(step)
    local mod = (step - 1) % 5
    if mod == 0 then
        return { {1, 1, 1, 1} }
    elseif mod == 1 then
        return { { 0, 1, 0 },
                 { 1, 1, 1 },
                 { 0, 1, 0 } }
    elseif mod == 2 then
        return { { 1, 1, 1 },
                 { 0, 0, 1 },
                 { 0, 0, 1 } }
    elseif mod == 3 then
        return { {1},
                 {1},
                 {1},
                 {1} }
    else
        return { { 1, 1 },
                 { 1, 1 } }
    end
end

local function print_grid(grid, hmax)
    local chars = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I' }
    for i = hmax, 1, -1 do
        for j = 1, #grid[i] do
            if grid[i][j] == 0 then
                io.write('.')
            elseif grid[i][j] == 1 then
                io.write('#')
            else
                local c = chars[(grid[i][j] % #chars) + 1]
                io.write(c)
            end
        end
        io.write('\n')
    end
end

local function create_map(h, w)
    local map = make_grid(h, w, 0)
    for j = 2, w - 1 do
        map[1][j] = 1
    end
    for i = 1, h do
        map[i][1] = 1
        map[i][w] = 1
    end
    return map
end

local function intersects(rock, map, ai, aj, int_off_i, int_off_j)
    local hrock, wrock = #rock, #rock[1]
    for io = 0, hrock - 1 do
        for jo = 0, wrock - 1 do
            if rock[io + 1][jo + 1] > 0 and map[ai + io + int_off_i][aj + jo + int_off_j] > 0 then
                return true
            end
        end
    end
    return false
end

--
-- i
-- ^
-- |
--  ---> j

local W = 7 + 2 -- +2 for sentinels
local jets = read_jets()
local ijet = 1
local njets = #jets
local map = create_map(10000, W)
local hmax = 1
-- print_grid(map, hmax)
-- print()
for step = 1, 2022 do
    local rock = make_rock(step)
    local hrock, wrock = #rock, #rock[1]
    local ai, aj = hmax + 4, 3 + 1
    while true do
        -- Jet move
        local jet = jets[ijet]
        if not intersects(rock, map, ai, aj, 0, jet) then
            aj = aj + jet
        end
        if ijet < njets then
            ijet = ijet + 1
        else
            ijet = 1
        end


        -- The main stuff
        -- Does going 1 lower intersect with anything?
--         local intersect = false
--         for io = 0, hrock - 1 do
--             for jo = 0, wrock - 1 do
--                 if rock[io + 1][jo + 1] > 0 and map[ai + io - 1][aj + jo] > 0 then
--                     intersect = true
--                 end
--             end
--         end

        if intersects(rock, map, ai, aj, -1, 0) then
            for io = 0, hrock - 1 do
                for jo = 0, wrock - 1 do
                    if rock[1 + io][1 + jo] > 0 then
                        map[ai + io][aj + jo] = step + 1
                    end
                end
            end
            hmax = max(hmax, ai + hrock - 1)
            break
        else
            ai = ai - 1
        end
    end
--     print_grid(map, hmax)
--     print()
end
print(hmax-1)
