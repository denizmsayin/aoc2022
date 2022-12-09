utils = require('lib/utils')

K = utils.is_part_1() and 4 or 14

-- Let's use metatables to make an object-style counter

Counter = {}
Counter.__index = Counter

function Counter.new()
    local o = { _size = 0 }
    setmetatable(o, Counter)
    return o
end

function Counter:add(k)
    if self[k] == nil then
        self[k] = 1
        self._size = self._size + 1
    else
        self[k] = self[k] + 1
    end
end

function Counter:remove(k)
    if self[k] == nil or self[k] <= 0 then
        error(string.format('Decrementing key "%s" which does not exist in the counter', k))
    end
    self[k] = self[k] - 1
    if self[k] == 0 then
        self[k] = nil
        self._size = self._size - 1
    end
end

function Counter:size() return self._size end

stream = io.read()
counter = Counter.new()
for i = 1, #stream do
    counter:add(stream:sub(i, i))
    if i > K then
        counter:remove(stream:sub(i-K, i-K))
    end
    if counter:size() == K then
        print(i)
        break
    end
end
