local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function read_cubes()
    local t = {}
    for line in io.lines() do
        local i, j, k = line:match('(%d+),(%d+),(%d+)')
        -- Add 2 to every index, 1 for sentinel, 1 for the 1-indexed lua
        table.insert(t, { tonumber(i) + 2, tonumber(j) + 2, tonumber(k) + 2 })
    end
    return t
end

local function cube_axis_max(cubes, axis)
    local max = 0
    for _, cube in ipairs(cubes) do
        local v = cube[axis]
        if v <= 1 then error(string.format('Got v=%d', v)) end
        if v > max then max = v end
    end
    return max
end

local function create_3d_grid(m, n, o, v)
    local t1 = {}
    for _ = 1, m do
        local t2 = {}
        for _ = 1, n do
            local t3 = {}
            for _ = 1, o do
                table.insert(t3, v)
            end
            table.insert(t2, t3)
        end
        table.insert(t1, t2)
    end
    return t1
end

-- Values: In part 1, 1 is cube, 0 outside
--         In part 2, 2 is in the droplet, 1 is cube, 0 is outside the droplet
--                    Outside is 2 initially, and 0s are added via some preprocessing

local DEFAULT_VALUE = utils.IS_PART_1 and 0 or 2

local function create_cube_grid(cubes)
    local imax = cube_axis_max(cubes, 1)
    local jmax = cube_axis_max(cubes, 2)
    local kmax = cube_axis_max(cubes, 3)
    return create_3d_grid(imax + 1, jmax + 1, kmax + 1, DEFAULT_VALUE) -- sentinels!
end

local function mark_cubes(grid, cubes)
    for _, cube in ipairs(cubes) do
        local i, j, k = compat.unpack(cube)
        grid[i][j][k] = 1
    end
end

local OFFSETS = { {1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1} }

local function in_bounds(grid, i, j, k)
    return 1 <= i and i <= #grid and 1 <= j and j <= #grid[1] and 1 <= k and k <= #grid[1][1]
end

local function fill_outside(grid)
    local s = { { 1, 1, 1 } }
    local c = 0
    grid[1][1][1] = 0 -- marker for outside
    while #s > 0 do
        local i, j, k = compat.unpack(table.remove(s))
        c = c + 1
        for _, offset in ipairs(OFFSETS) do
            local io, jo, ko = compat.unpack(offset)
            local ii, jj, kk = i + io, j + jo, k + ko
            if in_bounds(grid, ii, jj, kk) and grid[ii][jj][kk] == 2 then
                table.insert(s, { ii, jj, kk })
                grid[ii][jj][kk] = 0
            end
        end
    end
end

local function count_exposed_sides(grid)
    local c = 0
    for i = 1, #grid do
        for j = 1, #grid[i] do
            for k = 1, #grid[i][j] do
                if grid[i][j][k] > 0 then -- a cube!
                    for _, offset in ipairs(OFFSETS) do
                        local io, jo, ko = compat.unpack(offset)
                        local ii, jj, kk = i + io, j + jo, k + ko
                        if grid[ii][jj][kk] == 0 then
                            c = c + 1
                        end
                    end
                end
            end
        end
    end
    return c
end

local cubes = read_cubes()
local grid = create_cube_grid(cubes)
mark_cubes(grid, cubes)
if utils.IS_PART_2 then fill_outside(grid) end
print(count_exposed_sides(grid))

