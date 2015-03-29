local notifs={
	--["PixelToast/TestRepo"]={"#V"},
	["MightyPirates/OpenComputers"]={"#oc"},
}

function gitshorturl(url)
	local req=http("http://git.io/",{
		post="url="..urlencode(url),
		redirect=false,
	})
	return req.headers.location
end

local db=persist("github")
for repo,chan in pairs(notifs) do
	async.new(function()
		while true do
			local events=git.get("repos/"..repo.."/events")
			local mxid=0
			if next(events.data) then
				local ot={}
				for s,j in ipairs(events.data) do
					mxid=math.max(mxid,uniso8601(j.created_at))
					if uniso8601(j.created_at)>(db.lastupdate or 0) then
						local actype=j.payload.issue and "issue" or (j.payload.commit and "commit" or "pull request")
						local data=j.payload.comment or j.payload.issue or j.payload.pull_request
						local action=j.payload.action
						local tpe=j.payload.type
						local o=""
						if data and data.html_url then
							o=o..gitshorturl(data.html_url).." "..antiping(j.actor.login).." "
						else
							o=o..antiping(j.actor.login).." "
						end
						if action=="created" then
							o=o.."commented on "..actype.." ( "..(j.payload.issue or j.payload.pull_request).title.." )"
						elseif action=="reopened" then
							o=o.."reopened "..actype.." ( "..data.title.." )"
						elseif action=="closed" then
							o=o.."closed "..actype.." ( "..data.title.." )"
						elseif action=="opened" then
							o=o.."opened "..actype.." ( "..data.title.." )"
						elseif j.type=="ForkEvent" then
							o=o.."forked"
						elseif j.type=="WatchEvent" then
							if action=="started" then
								o=o.."started watching"
							else
								o=o.."stopped watching"
							end
						else
							o=o.."unable to parse "..paste(serialize(j,99999))
						end
						if j.type~="PushEvent" then
							table.insert(ot,o)
						end
					end
				end
				db.lastupdate=mxid
				ot=table.reverse(ot)
				if #ot>5 then
					irc.say(chan,"["..repo:match("/(.+)").."] "..(#ot).." updates "..paste(table.concat(ot,"\n")))
				else
					for k,v in ipairs(ot) do
						irc.say(chan,"["..repo:match("/(.+)").."] "..v)
					end
				end
			end
			async.wait(tonumber(events.headers["x-poll-interval"]) or 60)
		end
	end)
end
