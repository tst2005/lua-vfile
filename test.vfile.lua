
local vfile = require "vfile"

do
	local data = "abcde\nz"
	local x = vfile(data)

	local tmp = os.tmpname()
	local y = io.open(tmp, "w")
	y:write(data)
	y:close()
	y = io.open(tmp, "r")
	os.remove(tmp)

	--local fd = io.stdin
	for _, fd in ipairs{y, x} do
--print("test with fd", fd)
		assert( fd:seek("cur", 0) == 0 )

		assert(fd:read(1)=="a")
		assert(fd:read(2)=="bc")
		assert(fd:read(0)=="")
		assert(fd:read(3)=="de\n")
		assert(fd:read(3)=="z")

		assert(fd:seek("cur", 0) == #data )

		assert(fd:read(1)==nil)

		assert( fd:seek("cur",  0) == #data )
		assert( fd:seek("end",  0) == #data )
		assert( fd:seek("end", -1) == #data-1)
		assert( fd:seek("cur",  0) == #data-1)
		assert( fd:seek("cur",  1) == #data)
		assert( fd:seek("set", 0) == 0 )
		assert( fd:seek("set"   ) == 0 )

		assert( fd:seek("cur", 1) == 1)

--print("pass")
	end

	local z = vfile("aaa\nbbb\n\nccc")
	assert(z:read("*l")=="aaa")
	assert(z:read("*l")=="bbb")
	assert(z:read("*l")=="")
	assert(z:read("*l")=="ccc")

	local z = vfile("aaa\nbBb\n\nccc")
	assert(z:read("*L")=="aaa\n")
	assert(z:read(1)=="b")
	assert(z:read("*L")=="Bb\n")
	assert(z:read("*L")=="\n")
	assert(z:read("*L")=="ccc")

	if z.close then
		assert(tostring(z):find("^file %(0x[0-9a-fA-F]+%)$"))
		assert(pcall(function() z:close() end))
		assert(tostring(z):find("^file %(closed%)$"))
		assert(not pcall(function() z:close() end))
	end

	local z = vfile("aaabbbccc\nzzz")
		--       hello
	z:write("hello\n")
	z:seek("set")
	assert(z:read("*a")=="hello\nccc\nzzz")
	z:seek("set")
	assert(z:read(6)=="hello\n")
	assert(z:read("*l")=="ccc")
	assert(z:read("*l")=="zzz")
	print("ok")
end
