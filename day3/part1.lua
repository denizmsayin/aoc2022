function splithalf(str)
    local half = #str // 2
    return str:sub(1, half), str:sub(half + 1)
end

function find_common(s1, s2)
    for c in s1:gmatch'.' do
        if s2:find(c) then
            return c
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
    common = find_common(l, r)
    total = total + get_priority(common)
end
print(total)
