local utils = require 'lib/utils'
local compat = require 'lib/compat'

local function abs(x) return x < 0 and -x or x end
local function min(x, y) return x < y and x or y end
local function max(x, y) return x > y and x or y end

local function get_manhattan(p1, p2)
    return abs(p1.x - p2.x) + abs(p1.y - p2.y)
end

local function mkpoint(x, y) return { x = x, y = y } end

local function mksensor(p1, p2)
    return { pos = p1, beacon = p2, beacon_dist = get_manhattan(p1, p2) }
end

local function parse_sensor(line)
    local pattern = 'Sensor at x=(-?%d+), y=(-?%d+): closest beacon is at x=(-?%d+), y=(-?%d+)'
    local x1, y1, x2, y2 = line:match(pattern)
    local p1 = mkpoint(tonumber(x1), tonumber(y1))
    local p2 = mkpoint(tonumber(x2), tonumber(y2))
    return mksensor(p1, p2)
end

local function mkrange(s, e) return { s = s, e = e } end
local function cprange(r) return { s = r.s, e = r.e } end
local function mksymmrange(center, r) return mkrange(center - r, center + r) end
local function in_range(r, v) return r.s <= v and v <= r.e end

local function sensor_limits_at(sensor, y)
    local y_dist = abs(sensor.pos.y - y)
    local x_dist = sensor.beacon_dist - y_dist
    if x_dist >= 0 then
        return mksymmrange(sensor.pos.x, x_dist)
    else
        return nil
    end
end

local function ranges_intersect(r1, r2)
    return r1.e >= r2.s and r2.e >= r1.s
end

local function merge_1d(r1, r2) -- Assumes they can be merged!!!
    return mkrange(min(r1.s, r2.s), max(r1.e, r2.e))
end

local function print_ranges(ranges)
    for _, range in ipairs(ranges) do
        io.write(string.format('(%d, %d) ', range.s, range.e))
    end
    io.write('\n')
end

local function merge_ranges(ranges)
    -- Idea: Sort ranges by starting point
    -- Can attempt to merge consecutive ranges
    -- If one cannot merge with the next, it cannot merge with anything else after either
    local merged_ranges = {}
    table.sort(ranges, function(r1, r2) return r1.s < r2.s end)
    local i = 1
    local n = #ranges
    while i <= n do
        local j = i + 1
        local r = mkrange(ranges[i].s, ranges[i].e) -- shallow copy
        while j <= n do -- merge all that you can!
            if ranges_intersect(r, ranges[j]) then
                r = merge_1d(r, ranges[j])
            else
                break
            end
            j = j + 1
        end
        table.insert(merged_ranges, r)
        i = j
    end
    return merged_ranges
end

local function collect_sensor_limits_at(sensors, y)
    local ranges = {}
    for _, sensor in ipairs(sensors) do
        local r = sensor_limits_at(sensor, y)
        if r ~= nil then
            table.insert(ranges, r)
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
        s = s + range.e - range.s + 1
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

local function count_known_beacons_in(beacon_set, target_y)
    local c = 0
    for enc_pos, _ in pairs(beacon_set) do
        local pos = decode_pos(enc_pos)
        if pos.y == target_y then
            c = c + 1
        end
    end
    return c
end



-- Now for part 2...
-- We need "diagonal" ranges around the sensor areas
-- Then, we'll scan them in both diagonals until we find the one single empty spot

-- We'll still use ranges in this part, but using a fancy diagonal coordinate transformation
-- which makes our beacon areas look like squares. Let's define a fancy frame class for that.

-- DAxis 0: Top left to bottom right
-- DAxis 1: Top right to bottom left

local Frame = {}
Frame.__index = Frame

function Frame.new(xs, xe, ys, ye)
    local frame = { xs = xs, xe = xe, ys = ys, ye = ye }
    frame.diag_span = xe - xs + ye - ys
    setmetatable(frame, Frame)
    return frame
end

function Frame:translate(x, y)
    return x - self.xs, y - self.ys
end

function Frame:axis0_transform(x, y)
    local xp, yp = self:translate(x, y)
    return yp + xp + 1
end

function Frame:axis1_transform(x, y)
    local xp, yp = self:translate(x, y)
    return yp + (self.xe - xp) + 1
end

local function iswhole(x) return x == math.floor(x) end

function Frame:in_frame_grid(x, y)
    return iswhole(x) and iswhole(y) and self.xs <= x and x <= self.xe and self.ys <= y and y <= self.ye
end

function Frame:diag_in_frame(axis_value)
    return axis_value > 0 and axis_value < self.diag_span
end

function Frame:inverse_axis_transform(ax0, ax1)
    local s = ax0 + ax1 - 2 -- 2 * yp + xe
    local yp = (s - self.xe) / 2
    local xp = ax0 - yp - 1
    return xp + self.xs, yp + self.ys
end

function Frame.switchax(axis) return (axis + 1) % 2 end

-- Return the square representing the sensor in the frame
function Frame:sensor_square_transform(sensor)
    local p = sensor.pos
    local offset = sensor.beacon_dist
    local c0 = self:axis0_transform(p.x, p.y)
    local c1 = self:axis1_transform(p.x, p.y)
    return { mksymmrange(c0, offset), mksymmrange(c1, offset) }
end


local function range_diff(r1, r2)
    if ranges_intersect(r1, r2) then
        local s, e
        if r1.e <= r2.e then
            s, e = r1.s, r2.s - 1
        else
            s, e = r2.e + 1, r1.e
        end
        return mkrange(s, e) -- could be empty!!!
    else
        return r1
    end
end

local function range_empty(r) return r.s > r.e end

local function collect_transformed_squares(sensors, frame)
    local ssquares = {}
    for _, sensor in ipairs(sensors) do
        table.insert(ssquares, frame:sensor_square_transform(sensor))
    end
    return ssquares
end

local function collect_axis1_ranges_at(ssquares, axis0)
    local ranges = {}
    for _, sq in ipairs(ssquares) do
        local r0, r1 = compat.unpack(sq)
        if in_range(r0, axis0) then
            table.insert(ranges, r1)
        end
    end
    return merge_ranges(ranges)
end


local function find_empty_point(ssquares, frame)
    for _, sq in ipairs(ssquares) do -- loop over square ax0s
        local ax0r, ax1r = compat.unpack(sq)
        for _, ax0v in ipairs({ax0r.s - 1, ax0r.e + 1}) do -- check right before and after the sq
            if frame:diag_in_frame(ax0v) then
                local r = cprange(ax1r) -- a copy to diff with the others
                for _, other_ax1r in ipairs(collect_axis1_ranges_at(ssquares, ax0v)) do
                    r = range_diff(r, other_ax1r)
                    if range_empty(r) then
                        break
                    end
                end

                if not range_empty(r) then -- wow, found a slot!
                    -- There's still the issue of: is it inside the frame or not?
                    -- It is possible for two diagonals in the frame to meet outside too...
                    -- Trying both endpoints should suffice...
                    for _, d in pairs(r) do
                        local x, y = frame:inverse_axis_transform(ax0v, d)
                        if frame:in_frame_grid(x, y) then
                            return math.floor(x), math.floor(y)
                        end
                    end
                end
            end
        end
    end
    return nil
end

local Y
if arg[2] ~= nil then -- can also set limits with cli args!
    Y = tonumber(arg[2])
else
    Y = 2000000 -- 10 for example
end

local sensors = read_sensors()
if utils.IS_PART_1 then
    local beacon_set = collect_beacon_set(sensors)
    local ranges = merge_ranges(collect_sensor_limits_at(sensors, Y))
    local existing = count_known_beacons_in(beacon_set, Y)
    local impossible = sum_spans(ranges)
    print(impossible - existing)
else
    local ylim = 2 * Y
    local frame = Frame.new(0, ylim, 0, ylim)
    local ssquares = collect_transformed_squares(sensors, frame)
    local x, y = find_empty_point(ssquares, frame)
    print(4000000 * x + y)
end
