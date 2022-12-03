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

function splithalf(str)
    local half = #str // 2
    return str:sub(1, half), str:sub(half + 1)
end

function find_common(c1, c2)
    for k, v in pairs(c1) do
        if c2[k] and c2[k] > 0 then
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
for line in io.lines() do
    l, r = splithalf(line)
    c1 = make_counter(l)
    c2 = make_counter(r)
    common = find_common(c1, c2)
    total = total + get_priority(common)
end
print(total)
