function spsplit(string)
    left, right = string:match('([^%s]+)%s*(.*)')
    return left, right
end

function sum_dir_sizes(tree, limit)
    local size = 0
    local size_sum = 0
    for k, v in pairs(tree) do
        if k ~= '..' then
            if type(v) == 'number' then
                size = size + v
            else
                sub_size, sub_sum = sum_dir_sizes(v, limit)
                size = size + sub_size
                size_sum = size_sum + sub_sum
            end
        end
    end
    if size <= limit then
        size_sum = size_sum + size
    end
    return size, size_sum
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
size, size_sum = sum_dir_sizes(root, 100000)
print(size_sum)
