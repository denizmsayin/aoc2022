function parse_ranges(line)
    s1, e1, s2, e2 = line:match('(%d+)-(%d+),(%d+)-(%d+)')
    return tonumber(s1), tonumber(e1), tonumber(s2), tonumber(e2)
end

function contains(s1, e1, s2, e2)
    return s1 <= s2 and e2 <= e1
end

total = 0
for line in io.lines() do
    s1, e1, s2, e2 = parse_ranges(line)
    if contains(s1, e1, s2, e2) or contains(s2, e2, s1, e1) then
        total = total + 1
    end
end
print(total)
