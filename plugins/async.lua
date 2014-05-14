async={}
local resume
function async.new(func)
	local co=coroutine.create(func)
	local sfunc
	function sfunc(...)
		resume=sfunc
		hook.del(sfunc)
		local p={coroutine.resume(co,...)}
		assert(p[1],(p[2] or "").."\n"..debug.traceback(co))
		return unpack(p,2)
	end
	resume=sfunc
	assert(coroutine.resume(co))
	return sfunc
end
function async.pull(name)
	hook.new(name,resume)
	return coroutine.yield()
end
function async.wait(n)
	hook.new("timer_"..hook.timer(n),resume)
	coroutine.yield()
end
function async.socket(sk,err)
	assert(sk,err)
	return setmetatable({
		receive=function(len,timeout)
			if len and len<1 then
				return "",nil
			end
			hook.newsocket(sk)
			local resume=resume
			local nd
			if timeout then
				hook.new("timer_"..hook.timer(timeout),function()
					nd=true
				end)
			end
			hook.new("select",function()
				if nd then
					resume(nil,timeout)
				end
				local txt,err=sk:receive(len)
				if err~="timeout" then
					resume(txt,err)
					hook.stop()
				end
			end)
			local txt,err=coroutine.yield()
			hook.remsocket(sk)
			return txt,err
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
			hook.remsocket(sk)
			sk:close()
		end,
		sk=sk,
	},{__gc=function()
		hook.remsocket(sk)
		sk:close()
	end})
end
