function parse_ranges(line)
    s1, e1, s2, e2 = line:match('(%d+)-(%d+),(%d+)-(%d+)')
    return tonumber(s1), tonumber(e1), tonumber(s2), tonumber(e2)
end

function overlaps(s1, e1, s2, e2)
    return s2 <= e1 and s1 <= e2
end

total = 0
for line in io.lines() do
    s1, e1, s2, e2 = parse_ranges(line)
    if overlaps(s1, e1, s2, e2) then
        total = total + 1
    end
end
print(total)
