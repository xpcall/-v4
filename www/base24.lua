postdata=postdata or urldata or {}
local base="abcdefghijklmnopqrstuvwx"
print([[
<!doctype html>
<html>
	<form action="http://pt.ptoast.tk/base24.lua" method="post">
		from base24: <input type="text" name="from" value="]]..(postdata.from or "").."\"/> "..htmlencode(tobase(postdata.from or "",base))..[[<br>
		to base24: <input type="text" name="to" value="]]..(postdata.to or "").."\"/> "..htmlencode(tobase(postdata.to or "",nil,base))..[[<br>
		<input type="submit" value="Submit">
	</form>
</html>
]])