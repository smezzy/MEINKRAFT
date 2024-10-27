local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end

function love.conf(t)
    t.window.width = 960
    t.window.height = 720
    t.window.resizable = true
    t.window.title =" OPENGL :3"
    t.window.depth = 24
end