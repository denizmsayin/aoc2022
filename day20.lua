local utils = require 'lib/utils'

local function read_linked(key)
    local index = {}
    local node0
    local i = 0
    for l in io.lines() do
        local v = tonumber(l)
        i = i + 1
        index[i] = { value = key * v, next = nil, prev = nil }
        if v == 0 then
            node0 = index[i]
        end
    end

    for j = 2, i - 1 do
        index[j].next = index[j + 1]
        index[j].prev = index[j - 1]
    end
    index[i].next = index[1]
    index[i].prev = index[i-1]
    index[1].next = index[2]
    index[1].prev = index[i]

    return index, node0
end

local function llnext(node, n)
    for _ = 1, n do node = node.next end
    return node
end

local function shift_node(node, n)
    -- Shift more efficiently!
    -- First, remove thineself from the list.
    node.prev.next = node.next
    node.next.prev = node.prev
    -- Second, iterate and insert!
    if n > 0 then -- forward and AFTER
        local iter = node.prev
        for _ = 1, n do iter = iter.next end
        iter.next.prev = node
        node.next = iter.next
        iter.next = node
        node.prev = iter
    else -- backward and BEFORE
        local iter = node.next
        for _ = n, -1 do iter = iter.prev end
        iter.prev.next = node
        node.prev = iter.prev
        iter.prev = node
        node.next = iter
    end
end

-- Not only mod, but also choose the fast direction
-- Doubles execution speed as expected :)
local function mod_directed(sh, n)
    local l = n - 1
    local m = sh % l
    if m > l / 2 then -- go backwards if too long
        m = m - l
    end
    return m
end

local function mix(index)
    local n = #index
    for i = 1, n do
        local cell = index[i]
        local sh = mod_directed(cell.value, n)
        shift_node(cell, sh)
    end
end

local key, mix_count = 1, 1
if utils.IS_PART_2 then
    key, mix_count = 811589153, 10
end
local index, node0 = read_linked(key)
for _ = 1, mix_count do
    mix(index)
end
local node1k = llnext(node0, 1000)
local node2k = llnext(node1k, 1000)
local node3k = llnext(node2k, 1000)
print(node1k.value + node2k.value + node3k.value)

