postdata=postdata or {}
if postdata.text then
	local p=paste(postdata.text)
	print(p)
	irc.say("#ocbots",p)
else
	print("no data.")
end