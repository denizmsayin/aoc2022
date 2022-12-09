utils = require('lib/utils')

CAPACITY = 70000000
TARGET_SPACE = 30000000

function spsplit(string)
    left, right = string:match('([^%s]+)%s*(.*)')
    return left, right
end

function collect_dir_sizes_(tree, sizes)
    local size = 0
    for k, v in pairs(tree) do
        if k ~= '..' then
            if type(v) == 'number' then
                size = size + v
            else
                size = size + collect_dir_sizes_(v, sizes)
            end
        end
    end
    table.insert(sizes, size)
    return size
end

function collect_dir_sizes(root)
    local sizes = {}
    collect_dir_sizes_(root, sizes)
    return sizes
end

root = {}
current = nil
for line in io.lines() do
    word, target = spsplit(line)
    if word == '$' then
        cmd, target = spsplit(target)
        if cmd == 'cd' then
            if target == '/' then
                current = root
            else
                current = current[target]
            end
        end -- ignore the 'ls' command
    elseif word == 'dir' then
        current[target] = { ['..'] = current }
    else
        file_size = tonumber(word)
        current[target] = file_size
    end
end

dir_sizes = collect_dir_sizes(root)

if utils.is_part_1() then
    total = 0
    for _, v in ipairs(dir_sizes) do
        if v <= 100000 then
            total = total + v
        end
    end
    print(total)
else
    root_size = dir_sizes[#dir_sizes]
    unused_space = CAPACITY - root_size -- root is added last
    space_to_free = TARGET_SPACE - unused_space
    min_so_far = CAPACITY
    for _, v in ipairs(dir_sizes) do
        if v >= space_to_free and v < min_so_far then
            min_so_far = v
        end
    end
    print(min_so_far)
end

