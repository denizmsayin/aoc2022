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

local J_OFFSETS = { 0, -1, 1 } -- offsets to check to move down

local function sim_step(grid, m, prev_pos_stack)
    -- Use a pipelined SPEEDY approach:
    -- Store path of last grain in stack, start from previous step
    -- Remember: -1 is empty, 0 is path, 1 are grains
    -- Ret: i where the last sand grain stopped. m works for part 2 as sentinel, 0 if stk empty

    if prev_pos_stack[1] == nil then
        return 0
    end

    -- Otherwise, simulate by dropping a grain
    local i, j = table.unpack(table.remove(prev_pos_stack))
    local moved = true
    local ii, jj
    while i < m and moved do
        ii = i + 1
        moved = false
        for _, joff in ipairs(J_OFFSETS) do
            jj = j + joff
            if grid[ii][jj] < 0 then
                table.insert(prev_pos_stack, {i, j})
                i, j = ii, jj
                moved = true
                break
            end
        end
    end

    grid[i][j] = 1

    return i
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

-- Simply drop one grain all the way to the end. Makes visualization harder, but oh well!
local step = 0
local prev_pos_stack = {{1, 500 - joff}}
local stop_i = -1
while not (utils.IS_PART_1 and stop_i == m or utils.IS_PART_2 and stop_i == 0) do
    stop_i = sim_step(grid, m, prev_pos_stack)
    step = step + 1
end
print(step - 1)
