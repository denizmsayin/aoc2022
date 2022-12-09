utils = require('lib/utils')

function parse_ranges(line)
    s1, e1, s2, e2 = line:match('(%d+)-(%d+),(%d+)-(%d+)')
    return tonumber(s1), tonumber(e1), tonumber(s2), tonumber(e2)
end

function contains(s1, e1, s2, e2)
    return s1 <= s2 and e2 <= e1
end

function contains2(s1, e1, s2, e2)
    return contains(s1, e1, s2, e2) or contains(s2, e2, s1, e1)
end

function overlaps(s1, e1, s2, e2)
    return s2 <= e1 and s1 <= e2
end

check = utils.is_part_1() and contains2 or overlaps -- choose comparator
total = 0
for line in io.lines() do
    s1, e1, s2, e2 = parse_ranges(line)
    if check(s1, e1, s2, e2) then
        total = total + 1
    end
end
print(total)
