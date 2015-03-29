--[[local db=sql.new("didtoday").new("main","time","did")
hook.new("command_didtoday",function(user,chan,txt)
	if admin.auth(user) then
		db.insert({time=socket.gettime(),did=txt})
		return "Inserted"
	end
end)]]