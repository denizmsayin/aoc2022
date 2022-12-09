local utils = require('lib/utils')

NUM_TAILS = utils.is_part_1() and 1 or 9 -- different tail size depending on part

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

-- 64 bit ints in Lua 5.4, encode with an unsigned bit shift, add a big offset to make positive
ENC_OFF = 100000
local function encode_coord(i, j) return ((i + ENC_OFF) << 32) | (j + ENC_OFF) end

local function follow_steps(tail_positions, hi, hj, visited)
    for i = 1, #tail_positions do
        local ti, tj = table.unpack(tail_positions[i])
        ti, tj = follow_step(ti, tj, hi, hj)
        tail_positions[i] = { ti, tj }
        hi, hj = ti, tj
    end
    local ti, tj = table.unpack(tail_positions[#tail_positions])
    visited[encode_coord(ti, tj)] = true
end

local function table_size(table)
    local size = 0
    for _, v in pairs(table) do
        if v then
            size = size + 1
        end
    end
    return size
end

local function create_tails(size)
    local tails = {}
    for _ = 1, size do table.insert(tails, { 0, 0 }) end
    return tails
end

local offsets = { R = { 0, 1 }, L = { 0, -1 }, U = { -1, 0 }, D = { 1, 0 } }
local hi, hj = 0, 0
local tail_positions = create_tails(NUM_TAILS)
local visited = { [encode_coord(0, 0)] = true }
for line in io.lines() do
    local dir, steps = line:match('(%a) (%d+)')
    steps = tonumber(steps)
    local ioff, joff = table.unpack(offsets[dir])
    for _ = 1, steps do
        hi, hj = hi + ioff, hj + joff
        follow_steps(tail_positions, hi, hj, visited)
    end
end
print(table_size(visited))

