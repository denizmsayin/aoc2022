local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function abs(x)
    return x < 0 and -x or x
end

local function new_point(x, y)
    return { x = x, y = y }
end

local function get_manhattan(p1, p2)
    return abs(p1.x - p2.x) + abs(p1.y - p2.y)
end

local function min(x, y)
    return x < y and x or y
end

local function max(x, y)
    return x > y and x or y
end

local function new_sensor(p1, p2)
    return { pos = p1, beacon = p2, beacon_dist = get_manhattan(p1, p2) }
end

local function parse_sensor(line)
    local pattern = 'Sensor at x=(-?%d+), y=(-?%d+): closest beacon is at x=(-?%d+), y=(-?%d+)'
    local x1, y1, x2, y2 = line:match(pattern)
    local p1 = new_point(tonumber(x1), tonumber(y1))
    local p2 = new_point(tonumber(x2), tonumber(y2))
    return new_sensor(p1, p2)
end

local function sensor_limits_at(sensor, y)
    local y_dist = abs(sensor.pos.y - y)
    local x_dist = sensor.beacon_dist - y_dist
    if x_dist >= 0 then
        return sensor.pos.x - x_dist, sensor.pos.x + x_dist
    else
        return nil
    end
end

local function can_merge_1d(s1, e1, s2, e2)
    return e1 >= s2 and e2 >= s1
end

local function merge_1d(s1, e1, s2, e2) -- Assumes they can be merged!!!
    return min(s1, s2), max(e1, e2)
end

local function print_ranges(ranges)
    for _, range in ipairs(ranges) do
        io.write('(' .. table.concat(range, ', ') .. ') ')
    end
    io.write('\n')
end

local function merge_ranges(ranges)
    -- Idea: Sort ranges by starting point
    -- Can attempt to merge consecutive ranges
    -- If one cannot merge with the next, it cannot merge with anything else after either
    local merged_ranges = {}
    table.sort(ranges, function(s1, s2) return s1[1] < s2[1] end)
    local i = 1
    while i <= #ranges do
        local s1, e1 = compat.unpack(ranges[i])
        local j = i + 1
        while j <= #ranges do -- merge all that you can!
            local s2, e2 = compat.unpack(ranges[j])
            if can_merge_1d(s1, e1, s2, e2) then
                s1, e1 = merge_1d(s1, e1, s2, e2)
            else
                break
            end
            j = j + 1
        end
        table.insert(merged_ranges, {s1, e1})
        i = j
    end
    return merged_ranges
end

local function collect_sensor_limits_at(sensors, y)
    local ranges = {}
    for _, sensor in ipairs(sensors) do
        local s, e = sensor_limits_at(sensor, y)
        if s ~= nil then
            table.insert(ranges, {s, e})
        end
    end
    return ranges
end

local function read_sensors()
    local sensors = {}
    for line in io.lines() do
        table.insert(sensors, parse_sensor(line))
    end
    return sensors
end

local function sum_spans(ranges)
    local s = 0
    for _, range in ipairs(ranges) do
        s = s + range[2] - range[1] + 1
    end
    return s
end

-- Have to subtract the number of known beacons from the span sum...
-- But sensors can match the same beacons, so I need their set.
-- Ugh! Time to encode... Use strings to keep it simple.
local function encode_pos(p)
    return tostring(p.x) .. ',' .. tostring(p.y)
end

local function decode_pos(p)
    local x, y = p:match('(-?%d+),(-?%d+)')
    return { x = tonumber(x), y = tonumber(y) }
end

local function collect_beacon_set(sensors)
    local beacons = {}
    for _, sensor in ipairs(sensors) do
        local enc = encode_pos(sensor.beacon)
        beacons[enc] = true
    end
    return beacons
end

local function count_known_beacons_in(beacon_set, ranges, target_y)
    local c = 0
    for enc_pos, _ in pairs(beacon_set) do
        local pos = decode_pos(enc_pos)
        local y = pos.y
        if y == target_y then
            for _, range in ipairs(ranges) do
                local s, e = compat.unpack(range)
                    if s <= y and y <= e then
                        c = c + 1
                    end
            end
        end
    end
    return c
end

local function chop_range(s, e, slim, elim)
    if s < slim then
        s = slim
    end
    if e > elim then
        e = elim
    end
    return s, e
end

local function chop_ranges_(ranges, slim, elim)
    for i = 1, #ranges do
        local s, e = compat.unpack(ranges[i])
        s, e = chop_range(s, e, slim, elim)
        ranges[i] = {s, e}
    end
end

local Y = 2000000 -- 10 for example

if utils.IS_PART_1 then
    local sensors = read_sensors()
    local beacon_set = collect_beacon_set(sensors)
    -- local ranges = collect_sensor_limits_at(sensors, 2000000)
    local ranges = merge_ranges(collect_sensor_limits_at(sensors, Y))
    local existing = count_known_beacons_in(beacon_set, ranges, Y)
    local impossible = sum_spans(ranges)
    print(impossible - existing)
else
    local ylim = 2 * Y
    local full_span = ylim + 1
    local sensors = read_sensors()
    for y = 0, ylim do
        -- local ranges = collect_sensor_limits_at(sensors, 2000000)
        local ranges = collect_sensor_limits_at(sensors, y)
        ranges = merge_ranges(ranges)
        chop_ranges_(ranges, 0, ylim)
        -- local existing = 0--count_known_beacons_in(beacon_set, ranges, y)
        local impossible = sum_spans(ranges)
        if impossible == full_span - 1 then -- one space!
            local x = ranges[1][2] + 1-- should have two ranges (0, a), (a + 2, ylim)
            print(4000000 * x + y)
            break
        end
    end
end
