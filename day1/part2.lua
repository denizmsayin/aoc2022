sum = 0
values = {}
repeat
    l = io.read()
    n = tonumber(l)
    if n then
        sum = sum + n
    else
        table.insert(values, sum)
        sum = 0
    end
until l == nil
table.sort(values)
print(values[#values] + values[#values-1] + values[#values-2])
