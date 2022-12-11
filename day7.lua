local utils = require('lib/utils')

CAPACITY = 70000000
TARGET_SPACE = 30000000

local function spsplit(string)
    local left, right = string:match('([^%s]+)%s*(.*)')
    return left, right
end

File = {}

function File.new(name, size)
    return { name = name, size = size or 0, parent = nil }
end

-- Directory

Dir = { list = {} }
Dir.__index = Dir

function Dir.new(name)
    local o = File.new(name, 0)
    o.contents = {}
    setmetatable(o, Dir)
    table.insert(Dir.list, o)
    return o
end

function Dir:add_file(file)
    self.contents[file.name] = file
    file.parent = self

    -- size update
    local p = self
    while p ~= nil do
        p.size = p.size + file.size
        p = p.parent
    end
end


-- Parsing the terminal output and creating the hierarchy
local root = Dir.new('root')
local current = nil
for line in io.lines() do
    local word, target = spsplit(line)
    if word == '$' then
        local cmd
        cmd, target = spsplit(target)
        if cmd == 'cd' then
            if target == '/' then
                current = root
            elseif target == '..' then
                current = current.parent
            else
                current = current.contents[target]
            end
        end -- ignore the 'ls' command
    elseif word == 'dir' then
        current:add_file(Dir.new(target))
    else
        local file_size = tonumber(word)
        current:add_file(File.new(target, file_size))
    end
end

-- Applying the algorithm to the file list
if utils.IS_PART_1 then
    local total = 0
    for _, f in ipairs(Dir.list) do
        if f.size <= 100000 then
            total = total + f.size
        end
    end
    print(total)
else
    local unused_space = CAPACITY - root.size -- root is added last
    local space_to_free = TARGET_SPACE - unused_space
    local min_so_far = CAPACITY
    for _, f in ipairs(Dir.list) do
        if f.size >= space_to_free and f.size < min_so_far then
            min_so_far = f.size
        end
    end
    print(min_so_far)
end

