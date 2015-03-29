
hook.new("raw",function(txt)
	txt:gsub("^:"..cnick.." MODE "..cnick.." :%+i",function()
		send("CAP REQ account-notify")
		async.new(function()
			async.wait(2)
			send("JOIN ##powder-bots")
			send("JOIN ##derp-bots")
		end)
	end)
end)
hook.new("msg",function()
	
end)