local hooks={}
local timers={}
hook={
	interval=nil,
	sel={},
	rsel={},
	meta={},
	hooks=hooks,
	timers=timers,
}
local function nxt(tbl)
	local n=1
	while tbl[n] do
		n=n+1
	end
	return n
end

function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end

local ed
function hook.stop()
	ed=true
end
function hook.queue(name,...)
	local callback=hook.callback
	hook.callback=nil
	if type(name)~="table" then
		name={name}
	end
	local p={}
	for _,nme in pairs(name) do
		for k,v in tpairs(hooks[nme] or {}) do
			if v then
				ed=false
				hook.name=name
				p={v(...)}
				if callback then
					callback(unpack(p))
				end
				if ed then
					hook.del(v)
				end
			end
		end
	end
	return unpack(p)
end
function hook.newsocket(sk)
	sk:settimeout(0)
	table.insert(hook.sel,sk)
end
function hook.remsocket(sk)
	for k,v in pairs(hook.sel) do
		if v==sk then
			table.remove(hook.sel,k)
			return
		end
	end
end
function hook.newrsocket(sk)
	sk:settimeout(0)
	table.insert(hook.rsel,sk)
end
function hook.remrsocket(sk)
	for k,v in pairs(hook.rsel) do
		if v==sk then
			table.remove(hook.rsel,k)
			return
		end
	end
end
function hook.new(name,func,meta)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		hook.meta[nme]=meta
		hooks[nme]=hooks[nme] or {}
		table.insert(hooks[nme],func)
	end
	return func
end
function hook.timer(tme)
	local n=nxt(timers)
	timers[n]={tme,tme}
	hook.interval=math.min(tme,hook.interval or tme)
	return "timer_"..n
end
local lst=socket.gettime()
hook.new("select",function()
	local dt=socket.gettime()-lst
	local mn
	for num,tme in tpairs(timers) do
		timers[num][1]=timers[num][1]-dt
		if timers[num][1]<=0 then
			timers[num][1]=hook.queue("timer_"..num) and timers[num][2] or nil
			if not timers[num][1] then
				timers[num]=nil
			end
		else
			mn=math.min(mn or timers[num][1],mn or math.huge)
		end
	end
	if mn and mn+1>mn then
		hook.interval=mn
	end
	lst=socket.gettime()
end)
function hook.del(name)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		if type(nme)=="function" then
			for k,v in pairs(hooks) do
				for n,l in pairs(v) do
					if l==nme then
						hooks[k][n]=nil
					end
				end
			end
		else
			hooks[nme]=nil
		end
	end
end
