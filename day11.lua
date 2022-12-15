local utils = require 'lib/utils'

-- Storing item lists in monkey and passing them around resizeable arrays
-- seems to make the whole thing slow down a little (0.12s). 
-- Instead: store all the items in a global list, along with which monkey they belong to.
-- The key idea is that items will be processed again in the same round if they move to
-- a monkey with a higher index; but not if moving back. Thus, we can process the whole
-- round in one fell swoop through the item array, without moving anything around.

-- Doing this naively halved the time and I ended up at 0.06s. 
-- Further micro-optims on the tight loop did help, but only had a small effect:
-- * Pushing the round loop inside the play_rounds function.
-- * Inlining op evaluation to remove function call overhead

local function new_monkey(op, div, true_monkey, false_monkey)
    return { op = op, div = div, inspect_count = 0,
             true_monkey = true_monkey, false_monkey = false_monkey }
end

-- Compact storage: 
local function parse_op(op_string)
    local op, value = op_string:match('(.) (.+)')
    if value == 'old' then
        return { plus = false, value = nil }
    end
    return { plus = op == '+', value = tonumber(value) }
end

local function new_item(worry, owner)
    return { worry = worry, owner = owner }
end

local function read_monkey(items)
    local line = io.read()
    if line == nil then
        return nil
    end
    local id = tonumber(string.match(line, 'Monkey (%d):')) + 1 -- +1 to match lua indices

    local items_string = string.match(io.read(), '  Starting items: (.*)')
    for num in items_string:gmatch('%d+') do
        table.insert(items, new_item(tonumber(num), id))
    end

    local op_string = string.match(io.read(), '  Operation: new = old (.*)')
    local op = parse_op(op_string)

    local div = tonumber(string.match(io.read(), 'Test: divisible by (%d+)'))
    local true_monkey = tonumber(string.match(io.read(), '    If true: throw to monkey (%d+)'))
    local false_monkey = tonumber(string.match(io.read(), '    If false: throw to monkey (%d+)'))

    local _ = io.read()

    return new_monkey(op, div, true_monkey + 1, false_monkey + 1) -- +1 for lua inds
end

local function div_lcm(monkeys)
    local prod = 1 -- all divs seem to be prime
    for _, m in ipairs(monkeys) do
        prod = prod * m.div
    end
    return prod
end

local function play_rounds(monkeys, items, lcm, num_rounds)
    for _, item in ipairs(items) do
        local w = item.worry
        local i = item.owner
        local next_i = i
        for _ = 1, num_rounds do
            repeat
                i = next_i
                local monkey = monkeys[i]
                monkey.inspect_count = monkey.inspect_count + 1
                local op = monkey.op
                if op.plus then
                    w = w + op.value
                else
                    w = w * (op.value or w)
                end
                if lcm ~= 0 then
                    w = w % lcm
                else
                    w = math.floor(w / 3)
                end
                next_i = w % monkey.div == 0 and monkey.true_monkey or monkey.false_monkey
            until next_i < i
        end
    end
end

local monkeys, items = {}, {}
while true do
    local m = read_monkey(items)
    if m == nil then break end
    table.insert(monkeys, m)
end

local num_rounds, lcm
if utils.IS_PART_1 then
    num_rounds, lcm = 20, 0
else
    num_rounds, lcm = 10000, div_lcm(monkeys)
end

play_rounds(monkeys, items, lcm, num_rounds)

table.sort(monkeys, function(a, b) return a.inspect_count > b.inspect_count end)
print(monkeys[1].inspect_count * monkeys[2].inspect_count)

