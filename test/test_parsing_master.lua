local luaunit = require('luaunit.lua')
local os = require('os')
os.exit = os.exit or process.exit

function add(v1, v2)
	if v1 < 0 or v2 < 0 then
		error('Can only add postiive or null numbers, received ' .. v1 .. ' and ' .. v2)
	end
	if v1 == 0 or v2 == 0 then
		return 0
	end

	return v1 + v2
end

function testAddPositive()
	luaunit.assertEquals(add(1,1), 2)
end

function testAddZero()
	luaunit.assertEquals(add(1,0), 1)
	luaunit.assertEquals(add(0,5), 0)
	luaunit.assertEquals(add(0,0), 0)
end

_G['testAddPositive'] = testAddPositive
_G['testAddZero'] = testAddZero

os.exit(luaunit.LuaUnit.run())
