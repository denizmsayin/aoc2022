local utils = require('lib/utils')

Monkey = {}
Monkey.__index = Monkey

function Monkey.new(id, items, update, div, true_monkey, false_monkey)
    return { id = id, items = items, update = update, div = div,
             true_monkey = true_monkey, false_monkey = false_monkey, inspect_count = 0 }
end

local function parse_op(op_string)
    local op, value = op_string:match('(.) (.+)')
    value = (value == 'old') and nil or tonumber(value)
    return { plus = op == '+', value = value }
end

local function eval_op(old, op)
    local rhs = op.value or old -- use old if op.value == nil
    if op.plus then
        return old + rhs
    else
        return old * rhs
    end
end

local function read_monkey()
    local line = io.read()
    if line == nil then
        return nil
    end
    local id = tonumber(string.match(line, 'Monkey (%d):'))

    local items_string = string.match(io.read(), '  Starting items: (.*)')
    local items = {}
    for num in items_string:gmatch('%d+') do
        table.insert(items, tonumber(num))
    end

    local op_string = string.match(io.read(), '  Operation: new = old (.*)')
    local op = parse_op(op_string)

    local div = tonumber(string.match(io.read(), 'Test: divisible by (%d+)'))
    local true_monkey = tonumber(string.match(io.read(), '    If true: throw to monkey (%d+)'))
    local false_monkey = tonumber(string.match(io.read(), '    If false: throw to monkey (%d+)'))

    local _ = io.read()

    -- add 1 to match lua indices
    return Monkey.new(id + 1, items, op, div, true_monkey + 1, false_monkey + 1)
end

local function div_lcm(monkeys)
    local prod = 1 -- all divs seem to be prime
    for _, m in ipairs(monkeys) do
        prod = prod * m.div
    end
    return prod
end

local function play_round(monkeys)
    local lcm = div_lcm(monkeys)
    for i = 1, #monkeys do
        local monkey = monkeys[i]
        monkey.inspect_count = monkey.inspect_count + #monkey.items
        while #monkey.items > 0 do
            local item = table.remove(monkey.items)
            item = eval_op(item, monkey.update)
            if utils.is_part_1() then
                item = item // 3
            else
                item = item % lcm
            end
            local target = item % monkey.div == 0 and monkey.true_monkey or monkey.false_monkey
            table.insert(monkeys[target].items, item)
        end
    end
end

local monkeys = {}
while true do
    local m = read_monkey()
    if m == nil then break end
    table.insert(monkeys, m)
end

local num_rounds = utils.is_part_1() and 20 or 10000
for _ = 1, num_rounds do
    play_round(monkeys)
end

table.sort(monkeys, function(a, b) return a.inspect_count > b.inspect_count end)
print(monkeys[1].inspect_count * monkeys[2].inspect_count)

