function parse_grid_row(str)
    local lst = {}
    for c in str:gmatch'.' do
        table.insert(lst, tonumber(c))
    end
    return lst
end

function read_grid()
    local grid = {}
    for line in io.lines() do
        table.insert(grid, parse_grid_row(line))
    end
    return grid
end

function make_grid(rows, cols, value)
    local grid = {}
    for i = 1, rows do
        local row = {}
        for j = 1, cols do
            table.insert(row, value)
        end
        table.insert(grid, row)
    end
    return grid
end

function mark_max_updates(grid)
    local max, upd = -1, 0
    local rows, cols = #grid, #grid[1]
    local marker_grid = make_grid(rows, cols, false) 

    -- doing this without code duplication is brutal, so guess I won't...
    for i = 1, rows do
        max, upd = -1, 0
        for j = 1, cols do
            if grid[i][j] > max then
                max = grid[i][j]
                marker_grid[i][j] = true
            end
        end
    end
    for i = 1, rows do
        max, upd = -1, 0
        for j = cols, 1, -1 do
            if grid[i][j] > max then
                max = grid[i][j]
                marker_grid[i][j] = true
            end
        end
    end
    for j = 1, cols do
        max, upd = -1, 0
        for i = 1, rows do
            if grid[i][j] > max then
                max = grid[i][j]
                marker_grid[i][j] = true
            end
        end
    end
    for j = 1, cols do
        max, upd = -1, 0
        for i = rows, 1, -1 do
            if grid[i][j] > max then
                max = grid[i][j]
                marker_grid[i][j] = true
            end
        end
    end

    return marker_grid
end



grid = read_grid()
marker = mark_max_updates(grid)
count = 0
for i = 1, #marker do
    for j = 1, #marker[i] do
        if marker[i][j] then
            count = count + 1
        end
    end
end
print(count)
