
hook.new("raw",function(txt)
	txt:gsub("^:"..cnick.." MODE "..cnick.." :%+i",function()
		send("CAP REQ account-notify")
		send("JOIN ##powder-bots")
		send("JOIN ##derp-bots")
	end)
end)
hook.new("msg",function()
	
end)