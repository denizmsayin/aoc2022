local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function parse_grid_row(str)
    local lst = {}
    for c in str:gmatch'.' do
        table.insert(lst, tonumber(c))
    end
    return lst
end

local function read_grid()
    local grid = {}
    for line in io.lines() do
        table.insert(grid, parse_grid_row(line))
    end
    return grid
end

local function in_bounds(grid, i, j)
    return 1 <= i and i <= #grid and 1 <= j and j <= #grid[i]
end

OFFSETS = { {0, 1}, {0, -1}, {1, 0}, {-1, 0} }

local function is_visible(grid, ipos, jpos)
    local value = grid[ipos][jpos]
    for _, offset in ipairs(OFFSETS) do
        local ioff, joff = compat.unpack(offset)
        local i, j = ipos + ioff, jpos + joff
        local side_visible = true
        while in_bounds(grid, i, j) do
            if grid[i][j] >= value then
                side_visible = false
                break
            end
            i, j = i + ioff, j + joff
        end
        if side_visible then
            return true
        end
    end
    return false
end

local function count_visible(grid)
    local c = 0
    for i = 1, #grid do
        for j = 1, #grid[i] do
            if is_visible(grid, i, j) then
                c = c + 1
            end
        end
    end
    return c
end

local function scenic_score(grid, ipos, jpos)
    local value = grid[ipos][jpos]
    local score = 1
    for _, offset in ipairs(OFFSETS) do
        local ioff, joff = compat.unpack(offset)
        local i, j = ipos + ioff, jpos + joff
        local mult = 0
        while in_bounds(grid, i, j) do
            mult = mult + 1
            if grid[i][j] >= value then
                break
            end
            i, j = i + ioff, j + joff
        end

        if mult == 0 then
            score = 0
            break
        end

        score = score * mult
    end

    return score
end

local function best_scenic_score(grid)
    local best = 0
    for i = 1, #grid do
        for j = 1, #grid[i] do
            local score = scenic_score(grid, i, j)
            if score > best then
                best = score
            end
        end
    end
    return best
end

local grid = read_grid()
local func = utils.IS_PART_1 and count_visible or best_scenic_score
print(func(grid))
