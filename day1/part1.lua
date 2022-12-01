max = 0
sum = 0
repeat 
    l = io.read()
    n = tonumber(l)
    if n then
        sum = sum + n
    else
        if sum > max then
            max = sum
        end
        sum = 0
    end
until l == nil
print(max)
