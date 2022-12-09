utils = require('lib/utils')

sum = 0
list = {}
repeat 
    l = io.read()
    n = tonumber(l)
    if n then
        sum = sum + n
    else
        table.insert(list, sum)
        sum = 0
    end
until l == nil
table.sort(list) -- inefficient, but does the trick; ideally a partial sort
if utils.is_part_1() then
    print(list[#list])
else
    print(list[#list] + list[#list-1] + list[#list-2])
end

