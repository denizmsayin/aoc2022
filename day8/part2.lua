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

function scenic_score(grid, row, col)
    local rows, cols = #grid, #grid[1]
    
    -- edge check
    if row == 1 or row == rows or col == 1 or col == cols then
        return 0
    end

    local score = 1
    -- doing this without code duplication is brutal, so guess I won't..
    for j = col + 1, cols do
        if j == cols or grid[row][j] >= grid[row][col] then
            score = score * (j - col)
            break
        end
    end
    for j = col - 1, 1, -1 do
        if j == 1 or grid[row][j] >= grid[row][col] then
            score = score * (col - j)
            break
        end
    end
    for i = row + 1, rows do
        if i == rows or grid[i][col] >= grid[row][col] then
            score = score * (i - row)
            break
        end
    end
    for i = row - 1, 1, -1 do
        if i == 1 or grid[i][col] >= grid[row][col] then
            score = score * (row - i)
            break
        end
    end
    return score
end

function best_scenic_score(grid)
    local best = 0
    for i = 1, #grid do
        for j = 1, #grid[1] do
            local score = scenic_score(grid, i, j)
            if score > best then
                best = score
            end
        end
    end
    return best
end

grid = read_grid()
print(best_scenic_score(grid))
