local utils = require('lib/utils')

local function parse_path(line)
    local segs = {}
    for j, i in line:gmatch'(%d+),(%d+)' do
        table.insert(segs, { tonumber(i), tonumber(j) })
    end
    return segs
end

local function read_paths()
    local paths = {}
    for line in io.lines() do
        table.insert(paths, parse_path(line))
    end
    return paths
end

local function find_imax(paths)
    local imax = 0
    for _, path in ipairs(paths) do
        for _, seg in ipairs(path) do
            local i = seg[1]
            if i > imax then
                imax = i
            end
        end
    end
    return imax
end

local function filled_grid(m, n, v)
    local grid = {}
    for _ = 1, m do
        local row = {}
        for _ = 1, n do
            table.insert(row, v)
        end
        table.insert(grid, row)
    end
    return grid
end

local function offset_paths(paths, ioff, joff)
    for _, path in ipairs(paths) do
        for _, seg in ipairs(path) do
            seg[1] = seg[1] + ioff
            seg[2] = seg[2] + joff
        end
    end
end

local function mark_paths(grid, paths)
    for _, path in ipairs(paths) do
        for idx = 1, #path - 1 do
            local i1, j1 = table.unpack(path[idx])
            local i2, j2 = table.unpack(path[idx+1])
            if i1 == i2 then
                if j1 > j2 then
                    j1, j2 = j2, j1
                end
                for j = j1, j2 do
                    grid[i1][j] = 0
                end
            elseif j1 == j2 then
                if i1 > i2 then
                    i1, i2 = i2, i1
                end
                for i = i1, i2 do
                    grid[i][j1] = 0
                end
            else
                error 'not ready for this :('
            end
        end
    end
end

local function count_stopped_grains(grid)
    local c = 0
    for _, row in ipairs(grid) do
        for _, v in ipairs(row) do
            if v > 0 then
                c = c + 1
            end
        end
    end
    return c
end

local OFFSETS = { {1, 0}, {1, -1}, {1, 1} } -- offsets to check to move down

local function sim_step(grid, m, grains, step, source_j)
    -- Use a pipelined approach:
    -- Simulate each sand grain in the active list. Easy peasy.
    -- Remember: -1 is empty, 0 is path, > 0 are grains, with the number being the grain ID
    -- > 0 is kind of an artifact from the previous implementation, just setting to 1 would work
    -- Return: done, next_grains if steady state reached
    -- Using 1, 2, 3 instead of .gid, .i, .j for dubious efficiency atm

    local next_grains = {} -- keep the queue for next time

    -- For part 1, check for the first grain being at the edge
    if utils.IS_PART_1 then
        local first_grain = grains[1]
        if first_grain ~= nil and first_grain[2] == m then
            return true, next_grains
        end
    end

    -- For part 2, check for the source being blocked
    if utils.IS_PART_2 and grid[1][source_j] >= 0 then
        return true, next_grains
    end

    -- Otherwise, simulate
    -- The start will always contain the lowest moving grain, go from 1 to end
    for _, grain in ipairs(grains) do
        local gid, i, j = table.unpack(grain)
        local moved = false

        -- Try to move the grain down
        for _, off in ipairs(OFFSETS) do
            local ii, jj = i + off[1], j + off[2]
            if grid[ii][jj] < 0 then
                table.insert(next_grains, {gid, ii, jj}) -- reusing might be faster
                moved = true
                break
            end
        end

        if not moved then -- freeze on the grid, do not consider next time
            grid[i][j] = gid
        end
    end

    table.insert(next_grains, {step, 1, source_j}) -- new sand grain
    return false, next_grains
end

local paths = read_paths()
local imax = find_imax(paths)

-- What is the theoretical maximum span in which a grain of sand could land?
-- For a fully empty grid, would be 2*m - 1, the pyramid worst case
-- Shapes would not change this limit due to the falling pattern
-- So, m space to the left and m space to the right
local jmin, jmax = 500 - imax, 500 + imax

if utils.IS_PART_2 then -- add the extra segment at the end
    imax = imax + 2
    jmin, jmax = 500 - imax, 500 + imax
    table.insert(paths, { {imax, jmin}, {imax, jmax} })
end

local jspan = jmax - jmin + 3 -- 2 to sentinel
local joff = jmin - 2 -- to map all j's to 1
offset_paths(paths, 1, -joff) -- increase all i by 1 too for lua indexing

local m, n = imax + 1, jspan -- imax + 1 to make space for the grain at 0
local grid = filled_grid(m, n, -1)
mark_paths(grid, paths)

-- To optimize a bit, track a pipelined list of moving sand grains
-- Instead of looping over the whole grid at every step
-- Resting grains will be removed and inserted to the grid
local done, grains = false, {}
local source_j = 500 - joff
local step = 1
while true do
    done, grains = sim_step(grid, m, grains, step, source_j)
    if done then
        print(count_stopped_grains(grid))
        break
    end
    step = step + 1
end

--[[
-- Printer for debugging and fun
local function copy_grid(grid)
    local new = {}
    for _, row in ipairs(grid) do
        local new_row = {}
        for _, item in ipairs(row) do
            table.insert(new_row, item)
        end
        table.insert(new, new_row)
    end
    return new
end

local function print_grid(grid, grains)
    grid = copy_grid(grid)
    for _, grain in ipairs(grains) do
        local gid, i, j = table.unpack(grain)
        grid[i][j] = gid
    end
    for _, row in ipairs(grid) do
        for _, v in ipairs(row) do
            local ch = (v < 0 and '.' or (v == 0 and '#' or 'o'))
            io.write(ch)
        end
        io.write('\n')
    end
end
]]
