
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
		[1]=0,		-- cursor (read at datasub(1+cursor,1+cursor+len) )
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
	if cursor >= #data then return nil end -- [N2]
	if n=="*a" then
		local cursor2 = cursor
		_[1] = #data+1
		return data:sub(1+cursor2, -1) -- -1 or #data
	end
	if n=="*l" or n=="*L" then
		local e = string_find(data, "\n", 1+cursor, true)
		_[1] = (e or #data)
		if n=="*l" and e then
			e = e-1
		end
		return string_sub(data, 1+cursor, (e and e or -1))
	end
	assert(n>=0, "read(n): n must be positive")
	if cursor >= #data then return nil end -- [N2]
	n=math_floor(n) -- must use integer [N1]
	local v = string_sub(data, 1+cursor, cursor+n)
	_[1] = cursor+#v
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
	local cursor = _[1] or 0
	-- The default value for whence is "cur", and for cursor is 0
	if whence == "set" then
		cursor = offset
	elseif whence == "cur" then
		cursor = cursor + offset
	elseif whence == "end" then
		cursor = _.size + offset
		-- FIXME: limit max end ?
	end
	if not( cursor <= _.size+1) then
		print("FIXME: raise an out of range error ?")
	end
	_[1] = cursor
	return cursor
end

function fd_class:write(a1, ...)
	assert(...==nil, "multiple argument not-implemented-yet")
	if type(a1)=="number" then
		error("number argument is not-implemented-yet",2)
	end
	assert(type(a1)=="string", "invalid type argument#1")
	local wlen = #a1
	local _ = self._
	local cursor = _[1] or 0
	local data = _[0]
	local newdata = string_sub(data, 1,1+cursor-1)..a1..string_sub(data, 1+cursor+wlen, -1)
	local size = #newdata
	cursor = cursor + wlen
	_[0] = newdata
	_[1] = cursor
	_.size = size
end

-- $ lua -e 'print(io.stdout:seek("cur", 0))'
-- nil     Illegal seek    29


local function new(data)
	return fd_class.init(fd_class(), data)
end

return new

-- N1: else cursor will grow more than expected : 0.9 + 0.9 + 0.9 becomes more than 0
-- N2: for integer the condition are the same
--	1+cursor > #data  
--	cursor > #data-1
--	cursor >= #data
