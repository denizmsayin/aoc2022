K = 4

function counter_add(counter, k)
    if counter[k] == nil then
        counter[k] = 1
    else
        counter[k] = counter[k] + 1
    end
end

function counter_sub(counter, k)
    if counter[k] == nil or counter[k] <= 0 then
        error('Counter logic error')
    end
    counter[k] = counter[k] - 1
end

function counter_size(counter)
    local s = 0
    for _, v in pairs(counter) do
        if v > 0 then
            s = s + 1
        end
    end
    return s
end

stream = io.read()
counter = {}
for i = 1, #stream do
    counter_add(counter, stream:sub(i, i))
    if i > K then
        counter_sub(counter, stream:sub(i-K, i-K))
    end
    if counter_size(counter) == K then
        print(i)
        break
    end
end

