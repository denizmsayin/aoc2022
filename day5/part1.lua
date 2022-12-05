function store_stack_lines()
    local lines = {}
    while true do
        local line = io.read()
        if line == '' then break end
        table.insert(lines, line)
    end
    return lines
end

function get_stack_count(stack_lines)
    -- This isn't necessary, we can get the size from the length of stack lines
    -- But I want to 'overengineer' this, since I don't trust spaces (: Use the last line.
    local last_line = stack_lines[#stack_lines]
    local last_int = last_line:match('(%d+)%s*$')
    return tonumber(last_int)
end

function read_input_stacks()
    local stack_lines = store_stack_lines()
    local stack_count = get_stack_count(stack_lines)
    local stacks = {}
    for i = 1, stack_count do -- init the stacks
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

function apply_move(stacks, n, from, to)
    for i = 1, n do
        table.insert(stacks[to], table.remove(stacks[from]))
    end
end

stacks = read_input_stacks()
for line in io.lines() do -- rest of the move lines
    n, from, to = line:match('move (%d+) from (%d+) to (%d+)')
    n, from, to = tonumber(n), tonumber(from), tonumber(to)
    apply_move(stacks, n, from, to)
end

for _, stk in ipairs(stacks) do
    io.write(stk[#stk])
end
print()

