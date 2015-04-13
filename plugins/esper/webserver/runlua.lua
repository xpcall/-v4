local out=""
local env=setmetatable({
	print=function(...)
		out=out..table.concat({...}," ").."\r\n"
	end,
	write=function(...)
		out=out..table.concat({...}," ")
	end,
	_g=_G,
},{
	__index=_G,
})
env._G=env
local function err(cl,txt)
	local res={
		headers=webserver.defHeaders(),
		code=500,
		data="<html><head><title>Script error</title></head><h1>Script error</h1><br><h3>\n"..htmlencode(txt).."\n</h3></html>",
	}
	webserver.servehead(cl,res)
	webserver.serveres(cl,res)
end
function runlua(code,cl,res)
	if type(func)=="string" then
		local rr
		func,rr=loadstring(func,"="..cl.path)
		if not func then
			return err(cl,rr)
		end
	end
	setfenv(func,env)
	env.cl=cl
	env.res=res
	env.post=cl.post
	env.get=cl.get
	env.headers=res.headers
	out=""
	print("calling func")
	local ok,err=xpcall(func,debug.traceback)
	if not ok then
		return err(cl,err)
	end
	print("done")
	res.data=out
	webserver.serveres(cl,res)
end