function masterraceprosockethax(lport,thost,tport)
	local sv=async.socket(socket.bind("*",lport))
	print("start server")
	async.new(function()
		while true do
			print("server loop")
			local cl=sv.accept()
			print("got client")
			local csv=async.socket(socket.connect(thost,tport))
			async.new(function()
				print("starting 1")
				while true do cl.send(csv.receive("*a")) print("got server packet") end
			end)
			async.new(function()
				print("starting 2")
				while true do csv.send(cl.receive("*a")) print("got client packet") end
			end)
		end
	end)
end