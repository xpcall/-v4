-- import pluto, print out the version number 
-- and set non-human binary serialization scheme.
local eris=require('eris')
-- perms are items to be substituted at serialization
perms = {
	[coroutine.yield] = 1,
	[print] = 2,
}

-- the functions that we want to execute as a coroutine
function foo()
    local someMessage = 'And hello from a long dead variable!'
    print(someMessage)
	bar(someMessage)
end

function bar(msg)
    print('entered bar')
    -- bar runs to here then yields
    coroutine.yield()
    print(msg)
end
perms[bar]=3
-- create and start the coroutine
co = coroutine.create(foo)
coroutine.resume(co)

-- the coroutine has now stopped at yield. so we can
-- persist its state with pluto
buf = eris.persist(perms, co)

-- save the serialized state to a file
outfile = io.open("potato", 'wb')
outfile:write(buf)
outfile:close()