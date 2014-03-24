local hooks={}
local timers={}
hook={
	interval=nil,
	sel={},
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
function hook.queue(name,...)
	local callback=hook.callback
	hook.callback=nil
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		for k,v in tpairs(hooks[nme] or {}) do
			local p={v(...)}
			if callback then
				callback(unpack(p))
			end
			if p[1]==false then
				hook.del(v)
			end
		end
	end
end
function hook.newsocket(sk)
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
function hook.new(name,func)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		hooks[nme]=hooks[nme] or {}
		table.insert(hooks[nme],func)
	end
	return func
end
function hook.newTimer(tme)
	local n=nxt(timers)
	timers[n]=tme
	hook.interval=math.min(tme,hook.interval or tme)
	return n
end
local lst=socket.gettime()
hook.new("interval",function()
	local dt=socket.gettime()-lst
	local mn
	for num,tme in tpairs(timers) do
		timers[num]=timers[num]-dt
		if timers[num]<=0 then
			hook.queue("timer_"..num)
			timers[num]=nil
		else
			mn=math.min(mn or timers[num],mn)
		end
	end
	hook.interval=mn
	lst=socket.gettime()
end)
function hook.del(name)
	if type(name)~="table" then
		name={name}
	end
	for _,nme in pairs(name) do
		print("del "..nme)
		if type(name)=="function" then
			for k,v in pairs(hooks) do
				for n,l in pairs(v) do
					if l==name then
						hooks[k][n]=nil
					end
				end
			end
		else
			hooks[name]=nil
		end
	end
end