async={}
function async.new(func)
	local co=coroutine.create(func)
	local sfunc
	function sfunc(...)
		resume=sfunc
		assert(coroutine.resume(co,...))
		hook.del(sfunc)
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
	return {
		receive=function(len)
			hook.newsocket(sk)
			local resume=resume
			hook.new("select",function()
				local txt,err=sk:receive(len)
				if err~="timeout" then
					resume(txt,err)
				end
			end)
			local txt,err=coroutine.yield()
			hook.remsocket(sk)
			return txt,err
		end,
		send=function(txt)
			for l1=1,#txt,8192 do
				local c=true
				while c and not sk:send(txt,l1,l1+8191) do
					hook.newrsocket(sk)
					local a,b=async.pullHook("select")
					hook.remrsocket(sk)
					for k,v in pairs(b) do
						if v==sk then
							c=false
							break
						end
					end
				end
			end
		end,
		accept=function()
			hook.newsocket(sk)
			while true do
				local cl,err=sk:accept()
				print(cl,err)
				if err~="timeout" then
					print("REEEEEEEEEtttterghernjgberbo")
					hook.remsocket(sk)
					return cl,err
				end
				async.pull("select")
			end
		end,
		close=function()
			sk:close()
		end,
		sk=sk,
	}
end
