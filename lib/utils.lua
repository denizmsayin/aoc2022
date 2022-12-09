local utils = {}

_is_part_1 = nil

function utils.is_part_1()
    if _is_part_1 == nil then
        _is_part_1 = arg[1] == nil or (arg[1] ~= '2' and arg[1] ~= 'part2')
    end
    return _is_part_1
end

return utils
