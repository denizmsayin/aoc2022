local utils = require 'lib/utils'
local compat = require 'lib/compat'

INF_COST = 1000000000

local function read_grid()
    local grid = {}
    for line in io.lines() do
        local row = {}
        for c in line:gmatch'.' do
            table.insert(row, c)
        end
        table.insert(grid, row)
    end
    return grid
end

local function filled_grid_like(grid, v)
    local bg = {}
    for _, row in ipairs(grid) do
        local r = {}
        for _, _ in ipairs(row) do
            table.insert(r, v)
        end
        table.insert(bg, r)
    end
    return bg
end

local function find_letter(grid, letter)
    for i = 1, #grid do
        for j = 1, #grid[i] do
            if grid[i][j] == letter then
                return i, j
            end
        end
    end
end

local function in_bounds(grid, i, j)
    return 1 <= i and i <= #grid and 1 <= j and j <= #grid[i]
end

local function diff(c2, c1)
    if c2 == 'E' then
        c2 = 'z'
    end
    if c1 == 'S' then
        c1 = 'a'
    end
    return c2:byte() - c1:byte()
end

local function calculate_all_costs(grid, costs)
    -- Search in reverse: Find cost from E to all other cells, going in reverse
    local OFFSETS = { {1, 0}, {-1, 0}, {0, 1}, {0, -1} }
    local ei, ej = find_letter(grid, 'E')
    local queue = { {ei, ej} }
    costs[ei][ej] = 0
    while #queue > 0 do
        -- It's possible to avoid the bad performance here by using 'rounds' of
        -- BFS. i.e. Use two lists, empty the first one, fill the second one,
        -- and swap them around for the next round. But it's already fast...
        local ti, tj = compat.unpack(table.remove(queue, 1))
        local cost = costs[ti][tj]
        for _, off in ipairs(OFFSETS) do
            local ioff, joff = compat.unpack(off)
            local ni, nj = ti + ioff, tj + joff
            if in_bounds(grid, ni, nj) and costs[ni][nj] == INF_COST then
                local d = diff(grid[ti][tj], grid[ni][nj])
                if d <= 1 then
                    table.insert(queue, { ni, nj })
                    costs[ni][nj] = cost + 1
                end
            end
        end
    end
end

local function find_letter_min_cost(grid, costs, letter)
    local min = INF_COST
    for i = 1, #grid do
        for j = 1, #grid[i] do
            if grid[i][j] == letter and costs[i][j] < min then
                min = costs[i][j]
            end
        end
    end
    return min
end

local grid = read_grid()
local costs = filled_grid_like(grid, INF_COST)
calculate_all_costs(grid, costs)
local target_letter = utils.IS_PART_1 and 'S' or 'a'
print(find_letter_min_cost(grid, costs, target_letter))

