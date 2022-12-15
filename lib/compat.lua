local compat = {}

-- A series of functions useful for maintaining compatibility between
-- Lua 5.1 (LuaJIT) and Lua 5.4, since there are some breaking changes

local luajit
if _VERSION == 'Lua 5.1' then
    luajit = true
elseif _VERSION == 'Lua 5.4' then
    luajit = false
else
    error("This repository only supports Lua 5.1 (LuaJIT) and Lua 5.4. Yours is: " .. _VERSION)
end

compat.luajit = luajit

-- Table unpack: builtin in 5.1, but table. in 5.4
if compat.luajit then
    compat.unpack = unpack
else
    compat.unpack = table.unpack
end

-- Bitwise operations need compat, but I turned them into string
-- concats and have avoided them so far.

return compat
