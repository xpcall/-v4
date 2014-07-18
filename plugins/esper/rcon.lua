reqplugin("async.lua")

rcon={}
local conv,uconv
do
	local str_byte=string.byte
	local str_char=string.char
	local str_len=string.len
	local str_sub=string.sub
	local m_floor=math.floor
	function conv(txt,err)
		local s={str_byte(txt,1,4)}
		return s[1]+(s[2]*256)+(s[3]*65536)+(s[4]*16777216)
	end
	function uconv(num)
		return str_char(num%256,math.floor(num/256)%65535,math.floor(num/65535)%16777216,math.floor(num/16777216))
	end
end
do
	local _irc2mc={
		["$00"]="$f",
		["$01"]="$0",
		["$02"]="$1",
		["$03"]="$2",
		["$04"]="$c",
		["$05"]="$4",
		["$06"]="$5",
		["$07"]="$6",
		["$08"]="$e",
		["$09"]="$a",
		["$10"]="$3",
		["$11"]="$b",
		["$12"]="$9",
		["$13"]="$d",
		["$14"]="$8",
		["$15"]="$7",
		["\2"]="",
		["\9"]="",
		["\19"]="",
		["\15"]="$r",
		["\21"]="",
	}
	for k,v in pairs(_irc2mc) do
		_irc2mc[k]=nil
		_irc2mc[k:gsub("%$","\3")]=v:gsub("%$","\194\167")
	end
	local _mc2irc={}
	for k,v in pairs(_irc2mc) do
		if v~="" then
			_mc2irc[v]=k
		end
	end
	function mc2irc(txt)
		for k,v in pairs(_mc2irc) do
			txt=txt:gsub(k,v)
		end
		return txt
	end
	function irc2mc(txt)
		txt=txt:gsub("\3(%d+)",function(c) return "\3"..("0"):rep(2-#c)..c end)
		txt=txt:gsub("\3(%d%d),%d","\3%1,")
		txt=txt:gsub("\3(%d%d),(%d?)","\3%1")
		for k,v in pairs(_irc2mc) do
			txt=txt:gsub(k,v)
		end
		txt=txt:gsub("\3%d%d","")
		return txt
	end
end

local sv
local pass="314159"

local function packet(id,tpe,dat)
	local out=uconv(id)..uconv(tpe)..dat.."\0"
	return uconv(#out)..out
end

hook.new("command_rcon_connect",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	if sv then
		sv.close()
	end
	local ip,port=txt:match("(.+):(.+)")
	local err
	sv,err=socket.connect(ip,tonumber(port))
	if not sv then
		return err
	end
	sv=async.socket(sv)
	local res,err=sv.send(packet(math.random(0,255),3,pass.."\0"))
	if not res then
		return "Error: "..err
	end
	return "Connected."
end)
local req={}
local creq=0
hook.new("command_rcon",function(user,chan,txt)
	if not admin.auth(user) then
		return
	end
	if not sv then
		return "Server not connected."
	end
	local res,err=sv.send(packet(creq,2,txt.."\0"))
	req[creq]=user
	creq=(creq+1)%256
	if not res then
		return "Error: "..err
	end
end)
async.new(function()
	while true do
		while not sv do
			async.pull("command_rcon_connect")
		end
		local length=conv(sv.receive(4))
		local d=sv.receive(length)
		local id=conv(d:sub(1,4))
		local stype=conv(d:sub(5,8))
		d=d:sub(9,-2)
		if stype==0 and d~="\0" then
			if req[id] then
				irc.say(req[id].chan,req[id].nick..", "..mc2irc(d:sub(1,-2)))
			end
		else
			irc.say("#ocbots","id: "..id.." stype: "..stype.." data: "..table.concat({d:byte(1,-1)}," "))
		end
	end
end)
