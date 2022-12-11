local utils = require('lib/utils')

local function parse_ranges(line)
    local s1, e1, s2, e2 = line:match('(%d+)-(%d+),(%d+)-(%d+)')
    return tonumber(s1), tonumber(e1), tonumber(s2), tonumber(e2)
end

local function contains(s1, e1, s2, e2)
    return s1 <= s2 and e2 <= e1
end

local function contains2(s1, e1, s2, e2)
    return contains(s1, e1, s2, e2) or contains(s2, e2, s1, e1)
end

local function overlaps(s1, e1, s2, e2)
    return s2 <= e1 and s1 <= e2
end

local check = utils.IS_PART_1 and contains2 or overlaps -- choose comparator
local total = 0
for line in io.lines() do
    local s1, e1, s2, e2 = parse_ranges(line)
    if check(s1, e1, s2, e2) then
        total = total + 1
    end
end
print(total)
