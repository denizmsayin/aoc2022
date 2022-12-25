local utils = require 'lib/utils'

local function parse_monkey(line)
    local name, rest = line:match('^(%a+): (.*)$')
    if rest:match('^%d+$') then
        return name, tonumber(rest)
    else
        local lhs, op, rhs = rest:match('(%a+) (.) (%a+)')
        return name, { lhs = lhs, op = op, rhs = rhs }
    end
end

local function read_monkeys()
    local monkeys = {}
    for line in io.lines() do
        local name, expr = parse_monkey(line)
        monkeys[name] = expr
    end
    return monkeys
end

local function operate(op, a, b)
    if a == '?' or b == '?' then
        return '?'
    elseif op == '+' then
        return a + b
    elseif op == '-' then
        return a - b
    elseif op == '*' then
        return a * b
    else
        return a / b
    end
end

local function reverse_op(aisnum, op, a, b, r)
    if aisnum then
        if op == '+' then
            return r - a
        elseif op == '-' then
            return a - r
        elseif op == '*' then
            return r / a
        else
            return a / r
        end
    else
        if op == '+' then
            return r - b
        elseif op == '-' then
            return r + b
        elseif op == '*' then
            return r / b
        else
            return r * b
        end
    end
end

local monkeys = read_monkeys()

local function resolve(name)
    local node = monkeys[name]
    if type(node) == 'table' then
        local lhs = resolve(node.lhs)
        local rhs = resolve(node.rhs)
        local v = operate(node.op, lhs, rhs)
        if v ~= '?' then
            monkeys[name] = v
        end
        return v
    else -- number or '?' (ambiguous)
        return node
    end
end

local function solve(value, eq)
    if eq == '?' then -- base case, solved
        return value
    end

    -- Otherwise, reverse the operation
    local a, b = monkeys[eq.lhs], monkeys[eq.rhs]
    local aisnum = type(a) == 'number'
    local next_value = reverse_op(aisnum, eq.op, a, b, value)
    local next_monkey = aisnum and eq.rhs or eq.lhs
    return solve(next_value, monkeys[next_monkey])
end

local r
if utils.IS_PART_1 then
    r = resolve('root')
else
    monkeys.humn = '?'
    local left = resolve(monkeys.root.lhs)
    local right = resolve(monkeys.root.rhs)
    if left == '?' then -- always make right ambiguous for simplicity
        r = solve(right, monkeys[monkeys.root.lhs])
    else
        r = solve(left, monkeys[monkeys.root.rhs])
    end
end
print(string.format('%d', r))
