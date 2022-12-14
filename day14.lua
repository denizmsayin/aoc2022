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
            local i, j = table.unpack(seg)
            if i > imax then
                imax = i
            end
        end
    end
    return imax
end

local function filled_grid(m, n, v)
    local grid = {}
    for i = 1, m do
        local row = {}
        for j = 1, n do
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

local function print_grid(grid)
    for _, row in ipairs(grid) do
        for _, v in ipairs(row) do
            local ch = (v < 0 and '.' or (v == 0 and '#' or 'o'))
            io.write(ch)
        end
        io.write('\n')
    end
end

local OFFSETS = { {1, 0}, {1, -1}, {1, 1} } -- offsets to check to move down

local function sim_step(grid, m, n, step, sandpos)
    -- Use a pipelined approach:
    -- Start from lowest cell and go up, simulate sand you come across
    -- Finally, add one grain from the top
    -- If a grain falls into the abyss, we're done
    -- Remember: -1 is empty, 0 is path, > 0 are grains, with the number being the grain ID

    -- Special treatment for last row in part 1:
    if utils.IS_PART_1 then
        for j = 1, n do
            if grid[m][j] > 0 then
                return grid[m][j]
            end
        end
    end

    -- Simulate the rest
    for i = m - 1, 1, -1 do
        -- All the rest go through the rules
        for j = 2, n - 1 do
            local v = grid[i][j]
            if v > 0 then
                -- TODO: could cache resting sand grains for speed
                for _, off in ipairs(OFFSETS) do
                    local ii, jj = i + off[1], j + off[2]
                    if grid[ii][jj] < 0 then
                        grid[ii][jj] = v
                        grid[i][j] = -1
                        break
                    end
                end
            end
        end
    end

    if utils.IS_PART_2 and grid[1][sandpos] > 0 then
        return step -- first grain that could not enter
    end

    grid[1][sandpos] = step -- drop some sand

    return nil
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

local m, n = imax + 1, jspan
local grid = filled_grid(m, n, -1)
mark_paths(grid, paths)
local sandpos = 500 - joff
local step = 1
while true do
    local last = sim_step(grid, m, n, step, sandpos)
    if last then
        print(last - 1) -- last is the first one who fell
        break
    end
    if step % 100 == 0 then
        print_grid(grid)
        print()
    end
    step = step + 1
end
-- Printer for debugging
--[[
function Print_item(item)
    local t = type(item)
    if t == 'number' then
        io.write(tostring(item))
    else
        Print_list(item)
    end
end

function Print_list(list)
    io.write('[')
    for i = 1, #list - 1 do
        Print_item(list[i])
        io.write(',')
    end
    Print_item(list[#list])
    io.write(']')
end
]]
