local utils = require 'lib/utils'

local function calculate_register_values()
    local values = {}
    local x = 1
    for line in io.lines() do
        local cmd = line:sub(1, 4)
        if cmd == 'noop' then
            table.insert(values, x)
        else
            local change = tonumber(line:sub(6))
            table.insert(values, x)
            table.insert(values, x)
            x = x + change
        end
    end
    return values
end

local values = calculate_register_values()
if utils.IS_PART_1 then
    local cycles = { 20, 60, 100, 140, 180, 220 }
    local sum = 0
    for _, cycle in ipairs(cycles) do
        sum = sum + cycle * values[cycle]
    end
    print(sum)
else
    local cycle = 1
    for _ = 1, 6 do
        for j = 0, 39 do
            local x = values[cycle]
            local char = (x == j or x - 1 == j or x + 1 == j) and '#' or '.'
            io.write(char)
            cycle = cycle + 1
        end
        io.write('\n')
    end
end
