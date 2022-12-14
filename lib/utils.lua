local utils = {}

utils.IS_PART_1 = arg[1] == nil or (arg[1] ~= '2' and arg[1] ~= 'part2')
utils.IS_PART_2 = not utils.IS_PART_1

return utils
