local utils = require('lib/utils')

local function store_stack_lines()
    local lines = {}
    while true do
        local line = io.read()
        if line == '' then break end
        table.insert(lines, line)
    end
    return lines
end

local function get_stack_count(stack_lines)
    -- This isn't necessary, we can get the size from the length of stack lines
    -- But I want to 'overengineer' this, since I don't trust spaces (: Use the last line.
    local last_line = stack_lines[#stack_lines]
    local last_int = last_line:match('(%d+)%s*$')
    return tonumber(last_int)
end

local function read_input_stacks()
    local stack_lines = store_stack_lines()
    local stack_count = get_stack_count(stack_lines)
    local stacks = {}
    for _ = 1, stack_count do -- init the stacks
        table.insert(stacks, {})
    end
    for i = #stack_lines - 1, 1, -1 do -- in reverse order
        local line = stack_lines[i]
        for j = 1, stack_count do
            local sj = 4 * j - 2
            local char = line:sub(sj, sj)
            if char ~= ' ' then
                table.insert(stacks[j], char)
            end
        end
    end
    return stacks
end

local function move_one_by_one(stacks, n, from, to)
    for _ = 1, n do
        table.insert(stacks[to], table.remove(stacks[from]))
    end
end

local function move_batch(stacks, n, from, to)
    for i = #stacks[from] - n + 1, #stacks[from] do
        table.insert(stacks[to], stacks[from][i])
    end
    for _ = 1, n do
        table.remove(stacks[from])
    end
end

local apply_move = utils.is_part_1() and move_one_by_one or move_batch -- moving function choice
local stacks = read_input_stacks()
for line in io.lines() do -- rest of the move lines
    local n, from, to = line:match('move (%d+) from (%d+) to (%d+)')
    n, from, to = tonumber(n), tonumber(from), tonumber(to)
    apply_move(stacks, n, from, to)
end

for _, stk in ipairs(stacks) do
    io.write(stk[#stk])
end
print()

