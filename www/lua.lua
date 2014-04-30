postdata=postdata or {}
if postdata.text then
	print(({htmlencode(hook.queue("command_lua53",nil,nil,postdata.text))})[1])
end
print([[<!doctype html>
<html>
	<head>
		<script src="http://cdnjs.cloudflare.com/ajax/libs/ace/1.1.3/ace.js"></script>
		<style type="text/css" media="screen">
			#editor {
				width: 100%;
				height: 100%;
			}
			#container
			{
				position: absolute;
				top: 50;
				left: 50;
				width: 80%;
				height: 80%;
			}
		</style>
	</head>
	<body>
		<form action="http://71.238.153.166/lua.lua" method="post" onsubmit="onSubmit()">
			<input type="hidden" id="htext" name="text"/>
			<div id="container">
				<div id="editor">]]..htmlencode(postdata.text or 'print("Hello, World!")')..[[</div><br/>
				<input type="submit" value="Submit"/>
			</div>
		</form>
		<script>
			var editor = ace.edit("editor");
			editor.setTheme("ace/theme/eclipse");
			editor.getSession().setMode("ace/mode/lua");
			function onSubmit()
			{
				document.getElementById('htext').value = editor.getValue();
			}
		</script>
	</body>
</html>]])