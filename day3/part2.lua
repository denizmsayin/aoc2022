function make_counter(str)
    local tbl = {}
    for c in str:gmatch'.' do
        if tbl[c] then
            tbl[c] = tbl[c] + 1
        else
            tbl[c] = 1
        end
    end
    return tbl
end

function find_common(c1, c2, c3)
    for k, v in pairs(c1) do
        if c2[k] and c2[k] > 0 and c3[k] and c3[k] > 0 then
            return k
        end
    end
    error('Unable to find match')
end

function get_priority(char)
    if 'a' <= char and char <= 'z' then
        return char:byte() - string.byte('a') + 1
    else
        return char:byte() - string.byte('A') + 27
    end
end

total = 0
while true do
    l1 = io.read()
    if l1 == nil then
        break
    end
    l2 = io.read()
    l3 = io.read()
    c1 = make_counter(l1)
    c2 = make_counter(l2)
    c3 = make_counter(l3)
    common = find_common(c1, c2, c3)
    total = total + get_priority(common)
end
print(total)
