
local class = require "mini.class.pico"

local fd_class = class()

local math_floor = assert(math.floor)
local string_sub, string_find = assert(string.sub), assert(string.find)

local internal = "_"
--local internal = {}
-- [0] = data
-- [1] = cursor

local function usable(self)
	local _ = self[internal]
	if not _.opened then
		error( "attempt to use a closed file", 2) -- FIXME: 3 ?
	end
	return _
end

function fd_class:init(data)
	local zerox = tostring(self):match(": (0x.*)$")
	self[internal] = {
		[0]=data,	-- data
		[1]=1,		-- cursor (read at datasub(cursor,cursor+len) )
		[2]=zerox,	-- 0xffffffff
		opened = true,
		size = #data,
	}
	local mt = getmetatable(self)
	if not mt then mt = {} end
	function mt.__tostring()
		local _ = self[internal]
		return "file ("..tostring(_[2])..")"
	end
	return self
end


function fd_class:read(n)
	local _ = usable(self)
	local data = _[0]
	local cursor = _[1]
	assert(n=="*a" or n=="*l" or n=="*L" or type(n)=="number", "only read(number) implemented")
	if cursor > #data then return nil end
	if n=="*a" then
		local cursor2 = cursor
		_[1] = #data+1
		return data:sub(cursor2, -1)
	end
	if n=="*l" or n=="*L" then
		local e = string_find(data, "\n", cursor, true)
		local s = cursor
		_[1] = (e or #data)+1
		if n=="*l" then
			return string_sub(data, s, (e and (e-1) or -1))
		else
			return string_sub(data, s, (e and e or -1))
		end
	end
	assert(n>=0, "read(n): n must be positive")
	if cursor > #data then return nil end
	n=math_floor(n) -- must use integer [N1]
	local v = string_sub(data, cursor, cursor+n-1)
	_[1] = cursor+n
	return v
end

function fd_class:close()
	local _ = usable(self)
	_.opened = false
	_[2] = "closed"
	return true
end

function fd_class:seek(whence, offset)
	local _ = usable(self)
	whence = whence or "cur"
	offset = offset or 0
	local cursor = _[1] or 1
	-- The default value for whence is "cur", and for offset is 0
	if whence == "set" then
		cursor = 1 + offset
	elseif whence == "cur" then
		cursor = cursor + offset
	elseif whence == "end" then
		cursor = _.size+1
	end
	if not( cursor-1 <= _.size+1) then
		print("FIXME: raise an out of range error ?")
	end
	-- FIXME: assert(cursor-1 <= _.size+1)
	_.cursor = cursor
	return cursor -1
end

-- $ lua -e 'print(io.stdout:seek("cur", 0))'
-- nil     Illegal seek    29


local function new(data)
	return fd_class.init(fd_class(), data)
end

return new

-- N1: else cursor will grow more than expected : 0.9 + 0.9 + 0.9 becomes more than 0
