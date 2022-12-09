local utils = require('lib/utils')

local function sign(x) return x > 0 and 1 or -1 end

local function follow_step(ti, tj, hi, hj)
    local di, dj = hi - ti, hj - tj
    if -1 <= di and di <= 1 and -1 <= dj and dj <= 1 then
        return ti, tj
    elseif di == 0 then
        if dj == 2 then
            return ti, tj + 1
        else
            return ti, tj - 1
        end
    elseif dj == 0 then
        if di == 2 then
            return ti + 1, tj
        else
            return ti - 1, tj
        end
    else -- diagonal case
        return ti + sign(di), tj + sign(dj)
    end
end

local function encode_coord(i, j) return tostring(i) .. ',' .. tostring(j) end

local function table_size(table)
    local size = 0
    for _, v in pairs(table) do
        if v then
            size = size + 1
        end
    end
    return size
end

local offsets = { R = { 0, 1 }, L = { 0, -1 }, U = { -1, 0 }, D = { 1, 0 } }
local hi, hj, ti, tj = 0, 0, 0, 0
local visited = { [encode_coord(ti, tj)] = true }
for line in io.lines() do
    local dir, steps = line:match('(%a) (%d+)')
    steps = tonumber(steps)
    local ioff, joff = table.unpack(offsets[dir])
    for _ = 1, steps do
        hi, hj = hi + ioff, hj + joff
        ti, tj = follow_step(ti, tj, hi, hj)
        visited[encode_coord(ti, tj)] = true
    end
end
print(table_size(visited))

