local utils = require 'lib/utils'

-- Ultra hardcore (!) unprincipled iterative hand-rolled parser
-- Cool code simplification: inserting nil is the same
-- as inserting nothing in Lua, so we can do away with nil checks
local function parse_list(str) -- where's python's eval(..) when you need it eh?
    local stack = {}
    local value, cur, prev
    for c in str:gmatch'.' do
        if c == '[' then
            table.insert(stack, cur)
            cur = {}
        elseif '0' <= c and c <= '9' then
            local cv = c:byte() - string.byte('0')
            if value == nil then
                value = cv
            else
                value = 10 * value + cv
            end
        elseif c == ',' or c == ']' then
            table.insert(cur, value)
            value = nil
            if c == ']' then
                if #stack == 0 then -- done!!
                    return cur
                else
                    prev = table.remove(stack)
                end
                table.insert(prev, cur)
                cur = prev
            end
        else
            error(string.format("parse error, unexpected char '%s'", c))
        end
    end
    error 'parse error'
end

local function compare_num(n1, n2)
    if n1 < n2 then
        return -1
    elseif n1 == n2 then
        return 0
    else
        return 1
    end
end

local function compare_packets(l1, l2)
    local tl1, tl2 = type(l1), type(l2)
    if tl1 == 'number' and tl2 == 'number' then
        return compare_num(l1, l2)
    elseif tl1 == 'number' then
        l1 = { l1 }
    elseif tl2 == 'number' then
        l2 = { l2 }
    end

    -- List comparison
    local len1, len2 = #l1, #l2
    local minlen = len1 < len2 and len1 or len2
    for i = 1, minlen do
        local c = compare_packets(l1[i], l2[i])
        if c ~= 0 then
            return c
        end
    end -- no order decision
    return compare_num(len1, len2)
end

local function find(table, item)
    for i = 1, #table do
        if table[i] == item then
            return i
        end
    end
    return nil
end

if utils.IS_PART_1 then
    local sum = 0
    local i = 1
    while true do
        local line1 = io.read()
        if line1 == nil then break end
        local line2 = io.read()
        io.read()

        local l1 = parse_list(line1)
        local l2 = parse_list(line2)

        if compare_packets(l1, l2) < 0 then
            sum = sum + i
        end

        i = i + 1
    end
    print(sum)
else
    local div1, div2 = {{6}}, {{2}}
    local packets = { div1, div2 } -- ensure reference equality
    for line in io.lines() do
        if line ~= '' then
            table.insert(packets, parse_list(line))
        end
    end

    table.sort(packets, function(a, b) return compare_packets(a, b) < 0 end)
    local i = find(packets, div1)
    local j = find(packets, div2)
    print(i * j)
end

-- Printer for debugging
--[[
function Print_item(item)
    local t = type(item)
    if t == 'number' then
        io.write(tostring(item))
    else
        Print_list(item)
    end
end

function Print_list(list)
    io.write('[')
    for i = 1, #list - 1 do
        Print_item(list[i])
        io.write(',')
    end
    Print_item(list[#list])
    io.write(']')
end
]]
