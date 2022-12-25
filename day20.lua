local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function read_linked()
    local index = {}
    local node0
    local i = 0
    for l in io.lines() do
        local v = tonumber(l)
        i = i + 1
        index[i] = { value = v, next = nil, prev = nil }
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

local function fmtll(head)
    local acc = {}
    local p = head
    repeat
        table.insert(acc, p.value)
        p = p.next
    until p == head
    return string.format('[%s]', table.concat(acc, ', '))
end

local function llnext(node, n)
    local itr = node
    for _ = 1, n do itr = itr.next end
    return itr
end

local function nmod(x, n)
    local modulo = x % n
    if x >= 0 then
        return modulo
    else
        if modulo == 0 then
            return 0
        else
            return modulo - n
        end
    end
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

local function naive_shift(index)
    local n = #index
    for i = 1, n do
        local cell = index[i]
        shift_node(cell, cell.value)
--         print(fmtll(index[1]))
    end
end

local index, node0 = read_linked()
-- print(fmtll(index[1]))
naive_shift(index)
local node1k = llnext(node0, 1000)
local node2k = llnext(node1k, 1000)
local node3k = llnext(node2k, 1000)
-- print(node1k.value , node2k.value , node3k.value)
print(node1k.value + node2k.value + node3k.value)
-- print(lsf(arr))
-- naive_shift(arr)
-- print(lsf(arr))

