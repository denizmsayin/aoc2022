utils = require('lib/utils')

function splithalf(str)
    local half = #str // 2
    return str:sub(1, half), str:sub(half + 1)
end

function find_common(s1, s2, s3)
    for c in s1:gmatch'.' do
        if s2:find(c) and (s3 == nil or s3:find(c)) then
            return c
        end
    end
    return nil
end

function get_priority(char)
    if 'a' <= char and char <= 'z' then
        return char:byte() - string.byte('a') + 1
    else
        return char:byte() - string.byte('A') + 27
    end
end

total = 0
if utils.is_part_1() then
    for line in io.lines() do
        l, r = splithalf(line)
        common = find_common(l, r)
        total = total + get_priority(common)
    end
else
    while true do
        l1 = io.read()
        if l1 == nil then break end
        l2 = io.read()
        l3 = io.read()
        common = find_common(l1, l2, l3)
        total = total + get_priority(common)
    end
end
print(total)
