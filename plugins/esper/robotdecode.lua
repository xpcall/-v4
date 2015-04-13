local actions={
	[0]="ac_null",
	"ac_move",
	"ac_turn",
	"ac_arm",
	"ac_claw",
	"ac_tilt",
}
server.listen(4322,function(cl)
	print("got vex client")
	local slen=cl.receive()
	local len=assert(tonumber(slen))
	local data=cl.receive(len)
	print("got vex data ",#data)
	local function readFmt(fmt)
		local o=string.unpack(fmt,data)
		print("read "..string.packsize(fmt).." bytes")
		data=data:sub(string.packsize(fmt)+1)
		return o
	end
	while #data>0 do
		local id=readFmt("B")
		local param=readFmt("i4")
		cl.send(tostring(actions[id]).." "..param.."\n")
	end
	cl.close()
	print("done vex")
end)
