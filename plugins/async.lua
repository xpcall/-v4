async={}
local resume
function async.new(func,err)
	local co=coroutine.create(func)
	local sfunc
	function sfunc(...)
		resume=sfunc
		hook.del(sfunc)
		local p={coroutine.resume(co,...)}
		if coroutine.status(co)~="dead" and err and not p[1] then
			err((p[2] or "").."\n"..debug.traceback(co))
		end
		return unpack(p,2)
	end
	resume=sfunc
	assert(coroutine.resume(co))
	return sfunc
end
function async.pull(...)
	hook.new({...},resume)
	return coroutine.yield()
end
function async.wait(n)
	hook.new(hook.timer(n),resume)
	coroutine.yield()
end
function async.socket(sk,err)
	assert(sk,err)
	local out
	out=setmetatable({
		receive=function(len,pfx)
			local tmo=out.timeout
			if type(len)=="number" and len<1 then
				return "",nil
			elseif type(tmo)=="number" and tmo<=0 then
				return nil,"timeout"
			end
			hook.newsocket(sk)
			local resume=resume
			local stop=false
			if tmo then
				hook.new(hook.timer(tmo),function()
					stop=true
					resume(nil,"timeout")
				end)
			end
			hook.new("select",function()
				local txt,err,str=sk:receive(len)
				txt=txt or str
				if err~="timeout" then
					resume(txt,err)
					stop=true
					hook.stop()
				elseif stop then
					hook.stop()
				end
			end)
			local txt,err=coroutine.yield()
			hook.remsocket(sk)
			return (pfx or "")..txt,err
		end,
		send=function(txt)
			local ind=1
			local _,l=sk:getstats()
			local bse=l
			while true do
				local t,err,c=sk:send(txt,ind)
				if not t and err~="timeout" then
					return false,err
				end
				if not c then
					break
				end
				local _,sl=sk:getstats()
				ind=ind+(sl-l)
				l=sl
				hook.newrsocket(sk)
				async.pull("select")
				hook.remrsocket(sk)
			end
			return true
		end,
		accept=function()
			hook.newsocket(sk)
			while true do
				local cl,err=sk:accept()
				if err~="timeout" then
					hook.remsocket(sk)
					return async.socket(cl,err)
				end
				async.pull("select")
			end
		end,
		close=function()
			while hook.remsocket(sk) do end
			sk:close()
		end,
		sk=sk,
	},{__gc=function()
		while hook.remsocket(sk) do end
		sk:close()
	end})
	return out
end
