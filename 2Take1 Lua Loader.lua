local config = require("2take1 compat")

local og_g_keys = {}
for k, v in pairs(_G) do
	og_g_keys[k] = true
end

local function init()
	stand.action(stand.my_root(), "Reset State", {}, "", function()
		-- reset stand runtime
		util.reset_state()
		-- reset global vars to avoid scripts crying about already being loaded
		for k, v in pairs(_G) do
			if og_g_keys[k] == nil then
				_G[k] = nil
			end
		end
		-- reinit
		util.keep_running()
		init()
	end)

	local settings_list = stand.list(stand.my_root(), "settings", {}, "")
	stand.toggle(settings_list, "spoof 2take1 install dir", {}, "try's to redirect loaded scripts attempting to access resources from the 2take1 install directory to the \"From 2Take1Menu\" folder", function (value)
		config.spoof_2take1_install_dir = value
	end, true)

	local lua_list = stand.list(stand.my_root(), "Load Scripts")
	local dir = filesystem.stand_dir() .. "From 2Take1Menu\\scripts\\"
	if not filesystem.is_dir(dir) then
		filesystem.mkdir(dir)
	end
	local created_divider = false
	for i, path in ipairs(filesystem.list_files(dir)) do
		if filesystem.is_regular_file(path) then
			no_scripts = false
			path = string.sub(path, string.len(dir) + 1)
			stand.action(lua_list, path, {}, "", function()
				local chunk, err = loadfile(dir .. path)
				local status
				if chunk then
					if not created_divider then
						created_divider = true
						stand.divider(stand.my_root(), "Script Features")
					end
					status, err = xpcall(chunk, function(e)
						util.toast(e)
						util.log(debug.traceback(e, 2))
					end)
					if status then
						util.toast("Successfully loaded " .. path)
						return
					end
				end
				util.toast(err, TOAST_ALL)
			end)
		end
	end
end
init()
