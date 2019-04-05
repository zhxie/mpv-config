-- This script need mpv version at least 0.28.0

local settings = {
	-- osd when navigating in seconds, in fact, affect nothing
	osd_duration_seconds = 10,

	-- amount of entries to show before slicing. Optimal value depends on font/video size etc.
	showamount = 16,
	
	-- may cause lag on cursor moving when true
	show_detail = true,

	-- keybindings force override only while menu is visible
	-- allowing you to use common overlapping keybinds
	dynamic_binds = true,

	-- display signs, {"prefix", "suffix"}
	cursor_str = {"{\\fnConsolas}>\\h{\\fnArial}", ""},
	non_str = {"{\\fnConsolas}\\h\\h{\\fnArial}", ""},
	-- top and bottom if entries are sliced off from display
	menu_sliced_str = {"...", "..."},
	
	-- disabled item
	disabled_prefix = "{\\s1}{\\cCCCCCC}",
	disabled_suffix = "{\\s0}{\\cFFFFFF}",

	-- force ass style
	force_ass_style = [["Default.Fontname=FZZhunYuan-M02,Default.Fontsize=45,Default.Shadow=0,Default.Outline=3,Default.Spacing=3"]],

	-- shaders
	shaders = ""
}
require 'mp.options'
read_options(settings, "easymenu")

local utils = require 'mp.utils'
local msg = require 'mp.msg'

-- Property
-- todo: start from 1, cursor, a & b
cursor = 0
menuList = {
	{
		{ "Playback" },
		{ "Speed", "${speed}", "add speed +0.1", "%0.2f" },
		{ "Speed Transition", "", "script-binding toggle_speedtrans", "" },
		{ "Precise Seek", "${hr-seek}", [[cycle-values hr-seek "yes" "absolute"]], "" },
		{ "Loop", "disp#loop", "script#loop", "" },
		{ "A-B Loop", "disp#abloop", "ab-loop", "" },
		{ "Shuffle Playlist", "", "playlist-shuffle", "" }
	},
	{
		{ "Video" },
		{ "Video", "track#video", "cycle video", "" },
		{ "Hardware Decoding", "${hwdec} (${hwdec-current})", [[cycle-values hwdec "no" "auto" "auto-copy"]], "" },
		{ "Aspect Ratio", "${video-aspect}", [[cycle-values video-aspect "4:3" "16:9" "2.4:1" "-1"]], "%0.2f" },
		{ "Deinterlace", "${deinterlace}", "cycle deinterlace", "" },
		{ "Output Levels", "${video-output-levels}", "cycle video-output-levels", "" }
	},
	{
		{ "Audio" },
		{ "Audio", "track#audio", "cycle audio", "" },
		{ "Audio Channels", "${audio-channels}", [[cycle-values audio-channels "stereo" "auto-safe"]], "" },
		{ "Audio Pitch Correction", "${audio-pitch-correction}", "cycle audio-pitch-correction", "" },
		{ "Audio Exclusive", "${audio-exclusive}", "cycle audio-exclusive", "" },
		{ "Audio Delay", "${audio-delay}", "add audio-delay +0.100", "%0.2f" },
		{ "Restore Audio Delay", "", "set audio-delay 0", "" }
	},
	{
		{ "Subtitle" },
		{ "Subtitle", "track#sub", "cycle sub", "" },
		{ "Secondary Sub", "disp#2sub", "cycle secondary-sid", "" },
		{ "Subtitle Delay", "${sub-delay}", "add sub-delay +0.1", "%0.2f" },
		{ "Fix Subtitle Delay", "", "sub-step -1", "" },
		{ "Restore Subtitle Delay", "", "set sub-delay 0", "" },
		{ "Subtitle Position", "${sub-pos}%", "add sub-pos -1", "" },
		{ "Subtitle Scale", "${sub-scale}", "add sub-scale +0.05", "%0.2f" },
		{ "Subtitle Margins", "${sub-ass-force-margins}", "cycle sub-ass-force-margins ; cycle sub-use-margins", "" },
		{ "Force ASS Style", "disp#assstyle", "script#assstyle", "" }
	},
	{
		{ "Window" },
		{ "Fullscreen", "${fullscreen}", "cycle fullscreen", "" },
		{ "Always On Top", "${ontop}", "cycle ontop", "" }
	},
	{
		{ "Screenshot" },
		{ "Screenshot", "", "async screenshot video", "" },
		{ "Screenshot with Subtitle", "", "async screenshot", "" }
	},
	{
		{ "Audio Resampler" },
		{ "Audio Normalize Downmix", "${audio-normalize-downmix}", "cycle audio-normalize-downmix", "" }
	},
	{
		{ "Video Filter" },
		{ "Rotate", "${video-rotate}", "script#rotate", "" }
	},
	{
		{ "Video Filter (Software Decode)", "" },
		{ "Flip", "", "vf toggle lavfi=vflip", "" },
		{ "Mirror", "", "vf toggle lavfi=hflip", "" },
		{ "Crop", "", "script-message easymenu toggle-off ; script-message-to crop start-crop", "" },
		{ "Auto Crop", "", "script-binding auto_crop", "" },
		{ "Subtitle On Video", "", "script-message multi_sub", "" },
		{ "Clear Filter", "", [[vf clr ""]], "" }
	},
	{
		{ "GPU Renderer Options" },
		{ "Scale", "${scale}", [[cycle-values scale "bilinear" "spline36" "lanczos" "ewa_lanczos" "ewa_lanczossharp" "ewa_lanczossoft" "mitchell"]], ""},
		{ "Chroma Scale", "${cscale}", [[cycle-values cscale "bilinear" "spline36" "lanczos" "ewa_lanczos" "ewa_lanczossharp" "ewa_lanczossoft" "mitchell"]], "" },
		{ "Downscale", "${dscale}", [[cycle-values dscale "bilinear" "spline36" "lanczos" "ewa_lanczos" "ewa_lanczossharp" "ewa_lanczossoft" "mitchell"]], "" },
		{ "Time Scale", "${tscale}", [[cycle-values tscale "oversample" "linear" "catmull_rom" "mitchell" "bicubic"]], "" },
		{ "Correct Downscaling", "${correct-downscaling}", "cycle correct-downscaling", "" },
		{ "Linear Downscaling", "${linear-downscaling}", "cycle linear-downscaling", "" },
		{ "Sigmoid Upscaling", "${sigmoid-upscaling}", "cycle sigmoid-upscaling", "" },
		{ "Interpolation", "${interpolation}", "cycle interpolation", "" },
		{ "Dither Depth", "${dither-depth}", [[cycle-values dither-depth "no" "auto" "16"]], "" },
		{ "GLSL Shaders", "disp#shaders", "script#shaders", "" },
		{ "Deband", "${deband}", "cycle deband", "" },
		{ "FBO Format", "${fbo-format}", "script#fbo"}
	}, 
	{
		{ "GPU Renderer Options (Display)" },
		{ "Primary", "${target-prim}", "cycle target-prim ; set icc-profile-auto no", "" },
		{ "Gamma", "${target-trc}", "cycle target-trc ; set icc-profile-auto no", "" },
		{ "Load ICC Profile", "${icc-profile-auto}", "cycle icc-profile-auto ; set target-prim auto ; set target-trc auto", "" }
	},
	{
		{ "GPU Renderer Options (HDR)" },
		{ "Target Peak", "${target-peak}", "add target-peak +50", "%0.2f" },
		{ "HDR Tone Mapping", "${tone-mapping}", "cycle tone-mapping", "" },
		{ "Tone Mapping Desaturate", "${tone-mapping-desaturate}", "add tone-mapping-desaturate +0.25", "%0.2f" }
	},
	{
		{ "Miscellaneous" },
		{ "Video Sync", "${video-sync}", "cycle video-sync", "" },
		{ "Performance", "disp#perf", "script#perf", "" },
		{ "Hotkey Distribution", "", "script-binding Hotkey_Dist", "" },
		{ "MediaInfo", "", "script-binding mediainfo", "" }
	}
}

function get_menu_name(menuId)
	return menuList[menuId][1][1]
end

function get_item_count()
	local count = 0
	for i = 1, table.getn(menuList) do
		for j = 1, table.getn(menuList[i]), 1 do
			count = count + 1
		end
	end
	return count - table.getn(menuList)
end

function get_item(id)
	local count = 0
	for i = 1, table.getn(menuList) do
		if (count + table.getn(menuList[i]) - 1 >= id) then
			return menuList[i][id - count + 1]
		end
		count = count + table.getn(menuList[i]) - 1
	end
	return
end

function get_item_id_pairs(id)
	local count = 0
	local menuCount = 1
	for i = 1, table.getn(menuList) do
		if (count + (table.getn(menuList[i]) - 1) >= id) then
			return menuCount, id - count
		end
		count = count + (table.getn(menuList[i]) - 1)
		menuCount = menuCount + 1
	end
	return
end

function get_item_id(menuId, itemId)
	local count = 0
	if (menuId ~= 1) then
		for i = 1, menuId - 1, 1 do
			count = count + table.getn(menuList[i]) - 1
		end
	end
	return count + itemId
end

function get_item_name(id)
	local item = get_item(id)
	if (item == nil) then
		return
	end
	return item[1]
end

function get_item_display(id)
	local item = get_item(id)
	if (item == nil) then
		return
	end
	return item[2]
end

function get_item_property(id)
	local item = get_item(id)
	if (item == nil) then
		return
	end
	return item[3]
end

function get_item_format(id)
	local item = get_item(id)
	if (item == nil) then
		return
	end
	return item[4]
end

shaders = {}
function append_shader()
	if (settings.shaders ~= "") then
		shaders = split_string(settings.shaders, ',')
	end
end

function set_menu_shader_item_property()
	for i = 1, get_item_count(), 1 do
		if (get_item_property(i) == "script#shaders") then
			local property = ""
			if (settings.shaders ~= "") then
				property = "cycle-values glsl-shaders "
				for j = 1, table.getn(shaders), 1 do
					property = property .. [["]] .. shaders[j] .. [[" ]]
				end
				property = property .. [[""]]
			else
				property = ""
			end
			local menuId, id = get_item_id_pairs(i)
			menuList[menuId][id + 1][3] = property
		end
	end
end

function set_menu_fbo_format_item_property()
	for i = 1, get_item_count(), 1 do
		if (get_item_property(i) == "script#fbo") then
			local property = ""
			if (mp.get_property("gpu-api") == "opengl") then
				property = [[cycle-values fbo-format "auto" "rgba16f" "rgba32f"]]
			else
				property = [[cycle-values fbo-format "auto" "rgba16hf" "rgba32f"]]
			end
			local menuId, id = get_item_id_pairs(i)
			menuList[menuId][id + 1][3] = property
		end
	end
end

function showmenu(duration)
	-- read shaders create menu item
	if table.getn(shaders) == 0 then
		append_shader()
		set_menu_shader_item_property()
		set_menu_fbo_format_item_property()
	end
	-- do not display if no menu item
	plen = get_item_count()
	if plen == 0 then
		return
	end
	add_keybinds()
	-- build file info
	output = "{\\fs10}{\\bord0.8}{\\b1}Playing: {\\b0}"..mp.get_property('media-title').."\n\n"
	-- build menu info
	local thisMenuId, thisItemId = get_item_id_pairs(cursor + 1)
	output = output.."{\\b1}Menu - " .. get_menu_name(thisMenuId) .. " - " .. thisItemId .. " / " .. table.getn(menuList[thisMenuId]) - 1 .. "{\\b0}\n"
	-- build menu structure
	local b = cursor - math.floor(settings.showamount / 2)
	local showall = false
	local showrest = false
	if b < 0 then
		b = 0
	end
	if plen <= settings.showamount then
		b = 0
		showall = true
	end
	if b > math.max(plen - settings.showamount - 1, 0) then 
		b = plen - settings.showamount
		showrest = true
	end
	if b > 0 and not showall then
		output = output .. settings.menu_sliced_str[1] .. "\n"
	end
	-- build item list
	-- a refers to the id of rendered items, b refers to the id of first rendered item
	for a = b, b + settings.showamount - 1, 1 do
		if a == plen then
			break
		end
		isbold = false
		local aMenuId, aItemId = get_item_id_pairs(a+1)
		if aMenuId == thisMenuId then
			isbold = true
		end
		if get_item_display(a+1) ~= "" and (isbold == true or settings.show_detail == true) then
			if string.match(get_item_display(a+1), "track#") ~= nil then
				temp_1 = get_item_display(a+1)
				temp_2 = get_item_display(a+1)
				if string.gsub(temp_2, "track#(.+)", mp.get_property) ~= "no" then
					temp = get_item_name(a+1)..": "..string.gsub(temp_1, "track#(.+)", mp.get_property).." ("..string.gsub(get_item_display(a+1), "track#(.+)", trav_track_by_track)..")"
				else
					temp = get_item_name(a+1)..": "..string.gsub(temp_1, "track#(.+)", mp.get_property)
				end
			-- specific functions
			elseif string.match(get_item_display(a+1), "disp#2sub") ~= nil then
				if mp.get_property("secondary-sid") ~= "no" then
					temp = get_item_name(a+1)..": "..mp.get_property("secondary-sid").." ("..trav_track("sub", mp.get_property("secondary-sid"))..")"
				else
					temp = get_item_name(a+1)..": "..mp.get_property("secondary-sid")
				end
			elseif string.match(get_item_display(a+1), "disp#abloop") ~= nil then
				temp = get_item_name(a+1)..": "..format_time(mp.get_property("ab-loop-a")).." -> "..format_time(mp.get_property("ab-loop-b"))
			elseif string.match(get_item_display(a+1), "disp#loop") ~= nil then
				if mp.get_property("loop-playlist") == "inf" then
					temp = get_item_name(a+1)..": ".."playlist"
				elseif mp.get_property("loop-file") == "yes" then
					temp = get_item_name(a+1)..": ".."file"
				else
					temp = get_item_name(a+1)..": ".."no"
				end
			elseif string.match(get_item_display(a+1), "disp#assstyle") ~= nil then
				if mp.get_property("sub-ass-force-style") ~= "" then
					temp = get_item_name(a+1)..": yes"
				else
					temp = get_item_name(a+1)..": no"
				end
			elseif string.match(get_item_display(a+1), "disp#perf") ~= nil then
				temp = get_item_name(a+1)..": "..get_perf()
			elseif string.match(get_item_display(a+1), "disp#shaders") ~= nil then
				if (mp.get_property("glsl-shaders") or mp.get_property("opengl-shaders")) == "" then
					temp = get_item_name(a+1) .. ": no"
				else
					temp = get_item_name(a+1) .. ": " .. (mp.get_property("glsl-shaders") or mp.get_property("opengl-shaders"))
				end
			-- as default
			else
				local format = get_item_format(a+1)
				if (format == nil or format == "" ) then
					temp = get_item_name(a+1)..": "..string.gsub(get_item_display(a+1), "${(.-)}", mp.get_property)
				else
					temp = get_item_name(a+1)..": "..string.gsub(get_item_display(a+1), "${(.-)}", function(s) return string.format(format, mp.get_property(s)) end)
				end
			end
		-- no display
		else
			temp = get_item_name(a+1)
		end
		-- ass style
		if a ~= cursor and isbold == false then output = output..settings.non_str[1]..temp..settings.non_str[2].."\n" end
		if a == cursor and isbold == false then output = output..settings.cursor_str[1]..temp..settings.cursor_str[2].."\n" end
		if a ~= cursor and isbold == true then output = output.."{\\b1}"..settings.non_str[1]..temp..settings.non_str[2].."{\\b0}\n" end
		if a == cursor and isbold == true then output = output.."{\\b1}"..settings.cursor_str[1]..temp..settings.cursor_str[2].."{\\b0}\n" end
		if a == b+settings.showamount-1 and not showall and not showrest then
			output=output..settings.menu_sliced_str[2]
		end
	end
	-- EOF
	mp.osd_message(mp.get_property("osd-ass-cc/0") .. output .. mp.get_property("osd-ass-cc/1"), (tonumber(duration) or settings.osd_duration_seconds))

	if not menutimer:is_enabled() then
		keybindstimer:kill()
		keybindstimer:resume()
	end
end

function format_time(sec)
	t_hour = 0
	t_min = 0
	t_sec = 0
	
	if tonumber(sec) == nil then
		return "no"
	else
		sec = math.floor(tonumber(sec))
	end	
	
	t_sec = sec % 60
	t_min = math.floor((sec - t_sec) / 60)
	t_hour = sec - 60 * t_min - t_sec
	
	if t_hour < 10 then 
		s_hour = "0"..t_hour
	else
		s_hour = tostring(t_hour)
	end
	if t_min < 10 then
		s_min = "0"..t_min
	else
		s_min = tostring(t_min)
	end
	if t_sec < 10 then
		s_sec = "0"..t_sec
	else
		s_sec = tostring(t_sec)
	end

	return s_hour..":"..s_min..":"..s_sec
end

function trav_track(type, id)
	local track_s
	for i=0,mp.get_property("track-list/count"),1 do
		if mp.get_property("track-list/"..i.."/type") == type and mp.get_property("track-list/"..i.."/id") == id then
			if mp.get_property("track-list/"..i.."/lang") == nil then
				track_s = "(unknown)"
			else
				track_s = "(" .. mp.get_property("track-list/"..i.."/lang") .. ")"
			end
			if mp.get_property("track-list/"..i.."/title") == nil then
				return track_s .. " " .. "und"
			else
				return track_s .. " " .. mp.get_property("track-list/"..i.."/title")
			end
		end
	end
	return "nil"
end

function trav_track_by_track(type)
	return trav_track(type, mp.get_property(type))
end

perf = {
	{"Customized", "scale", "cscale", "dscale", "dither-depth", "correct-downscaling", "linear-downscaling", "sigmoid-upscaling", "glsl-shaders", "deband", "fbo-format"},
	{"Standard Quality", "bilinear", "bilinear", "bilinear", "no", "no", "yes", "no", "", "no", "auto"},
	{"High Quality", "spline36", "spline36", "mitchell", "auto", "yes", "yes", "yes", "", "yes", "auto"},
	{"🥉 Jiji's Select", "ewa_lanczossharp", "ewa_lanczossoft", "mitchell", "16", "yes", "yes", "yes", "", "yes", "auto"},
	{"🥈 Jiji's Choice", "ewa_lanczossharp", "ewa_lanczossoft", "mitchell", "16", "yes", "yes", "yes", "~~/shaders/ravu-r4-chroma-left.hook,~~/shaders/ravu-r4.hook", "yes", "auto"},
	{"🥇 Jiji's Prime", "ewa_lanczossharp", "ewa_lanczossoft", "mitchell", "16", "yes", "yes", "no", "~~/shaders/KrigBilateral.glsl,~~/shaders/SSimSuperRes.glsl", "yes", "rgba32f"},
	{"👎 Hehe's Choice", "bilinear", "bilinear", "bilinear", "no", "no", "yes", "no", "~~/shaders/acme-0.5x.hook", "no", "auto"}
}

function split_string(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

function get_perf()
	for i = 2, table.getn(perf), 1 do
		local correct = 0
		for j = 2, table.getn(perf[1]), 1 do
			if (perf[i][j] == mp.get_property(perf[1][j])) then
				correct = correct + 1
			end
		end
		if (correct == table.getn(perf[1]) - 1) then
			return perf[i][1]
		end
	end
	return perf[1][1]
end

function set_perf_id(id)
	if (id > table.getn(perf)) then
		return
	end
	if (id <= 1) then
		return
	end
	for i = 2, table.getn(perf[1]), 1 do
		if (perf[1][i] == "glsl-shaders") then
			mp.command([[change-list glsl-shaders clr ""]])
			local glslShader = split_string(perf[id][i], ',')
			for i = 1, table.getn(glslShader), 1 do
				mp.command("change-list glsl-shaders append " .. glslShader[i])
			end
		else
			mp.set_property(perf[1][i], perf[id][i])
		end
	end
end

function set_perf_cycle(next)
	local perfName = get_perf()
	local perfId = 1
	local nextId = 1
	for i = 2, table.getn(perf), 1 do
		if (perf[i][1] == perfName) then
			perfId = i
		end
	end
	if (next == true) then
		if (perfId >= table.getn(perf)) then
			nextId = 2
		else
			nextId = perfId + 1
		end
	else
		if (perfId <= 2) then
			nextId = table.getn(perf)
		else
			nextId = perfId - 1
		end
	end
	set_perf_id(nextId)
end

function modify_prop()
	if plen == 0 then return end
	-- specific functions
	if string.match(get_item_property(cursor+1), "script#rotate") ~= nil then
		if mp.get_property("video-rotate") == "270" then
			mp.command("set video-rotate 0")
		else
			mp.command("add video-rotate 90")
		end
	elseif string.match(get_item_property(cursor+1), "script#loop") ~= nil then
		if mp.get_property("loop-playlist") == "inf" then
			mp.command([[set loop-playlist "no" ; set loop-file "inf"]])
		elseif mp.get_property("loop-file") == "yes" then
			mp.command([[set loop-playlist "no" ; set loop-file "no"]])
		else
			mp.command([[set loop-playlist "inf" ; set loop-file "no"]])
		end
	elseif string.match(get_item_property(cursor+1), "script#assstyle") ~= nil then
		if mp.get_property("sub-ass-force-style") == "" then
			mp.command("set sub-ass-force-style "..settings.force_ass_style)
		else
			mp.command([[set sub-ass-force-style ""]])
		end
		mp.command("sub-reload "..mp.get_property("sub"))
	elseif string.match(get_item_property(cursor+1), "script#perf") ~= nil then
		set_perf_cycle(true)
	-- as default
	else
		mp.command(get_item_property(cursor+1))
	end
	showmenu()
end

function modify_prop_reverse()
	if plen == 0 then return end
	if string.match(get_item_property(cursor+1), "script#rotate") ~= nil then
		if mp.get_property("video-rotate") == "0" then
			mp.command("set video-rotate 270")
		else
			mp.command("add video-rotate -90")
		end
	elseif string.match(get_item_property(cursor+1), "script#loop") ~= nil then
		if mp.get_property("loop-playlist") == "inf" then
			mp.command([[set loop-playlist "no" ; set loop-file "no"]])
		elseif mp.get_property("loop-file") == "yes" then
			mp.command([[set loop-playlist "inf" ; set loop-file "no"]])
		else
			mp.command([[set loop-playlist "no" ; set loop-file "inf"]])
		end
	elseif string.match(get_item_property(cursor+1), "script#assstyle") ~= nil then
		if mp.get_property("sub-ass-force-style") == "" then
			mp.command("set sub-ass-force-style "..settings.force_ass_style)
		else
			mp.command([[set sub-ass-force-style ""]])
		end
		mp.command("sub-reload "..mp.get_property("sub"))
	elseif string.match(get_item_property(cursor+1), "script#perf") ~= nil then
		set_perf_cycle(false)
	-- as default
	elseif string.match(get_item_property(cursor+1), "cycle%-values") ~= nil then
		mp.command(string.gsub(get_item_property(cursor+1), "cycle%-values (.*)", "cycle%-values !reverse %1"))
	elseif string.match(get_item_property(cursor+1), "cycle") ~= nil then
		mp.command(get_item_property(cursor+1).." down")
	elseif string.match(get_item_property(cursor+1), "add") ~= nil then
		if string.match(get_item_property(cursor+1), "+") ~= nil then
			mp.command(string.gsub(get_item_property(cursor+1), "+(%d+)", "-%1"))
		else
			mp.command(string.gsub(get_item_property(cursor+1), "-(%d+)", "+%1"))
		end
	elseif string.match(get_item_property(cursor+1), "sub%-step") ~= nil then
		if string.match(get_item_property(cursor+1), "+") ~= nil then
			mp.command("sub-step -1")
		else
			mp.command("sub-step +1")
		end
	else
		mp.command(get_item_property(cursor+1))
	end
	showmenu()
end

function moveup()
	if plen == 0 then return end
	if cursor ~= 0 then
		cursor = cursor - 1
	else
		cursor = plen - 1
	end
	showmenu()
end

function movedown()
	if plen == 0 then return end
	if cursor ~= plen-1 then
		cursor = cursor + 1
	else
		cursor = 0
	end
	showmenu()
end

function moveprevcat()
	if plen == 0 then
		return
	end
	menuId, itemId = get_item_id_pairs(cursor + 1)
	if menuId ~= 1 then
		cursor = get_item_id(menuId - 1, 1) - 1
	else
		cursor = get_item_id(table.getn(menuList), 1) - 1
	end
	showmenu()
end

function movenextcat()
	if plen == 0 then
		return
	end
	menuId, itemId = get_item_id_pairs(cursor+ 1)
	if menuId ~= table.getn(menuList) then
		cursor = get_item_id(menuId + 1, 1) - 1
	else
		cursor = get_item_id(1, 1) - 1
	end
	showmenu()
end

function add_keybinds()
	mp.add_forced_key_binding('UP', 'moveup', moveup, "repeatable")
	mp.add_forced_key_binding('DOWN', 'movedown', movedown, "repeatable")
	mp.add_forced_key_binding('LEFT', 'moveprevcat', moveprevcat, "repeatable")
	mp.add_forced_key_binding('RIGHT', 'movenextcat', movenextcat, "repeatable")
	mp.add_forced_key_binding('ENTER', 'modify_prop', modify_prop, "repeatable")
	mp.add_forced_key_binding('SHIFT+ENTER', 'modify_prop_reverse', modify_prop_reverse, "repeatable")
end

function remove_keybinds()
	if settings.dynamic_binds then
		mp.remove_key_binding('moveup')
		mp.remove_key_binding('movedown')
		mp.remove_key_binding('moveprevcat')
		mp.remove_key_binding('movenextcat')
		mp.remove_key_binding('modify_prop')
		mp.remove_key_binding('modify_prop_reverse')
	end
end

function toggle_menu()
    -- Disable
	if mp.get_property("media-title") ~= nil then
		if menutimer:is_enabled() then
			menutimer:kill()
			remove_keybinds()
			mp.osd_message("", 0)
		-- Enable
		else
			menutimer:resume()
			showmenu()
		end
	end
end

function toggle_menu_perf()
	if not menutimer:is_enabled() then
		for i = 1, get_item_count(), 1 do
			if get_item_name(i) == "Performance" then
				cursor = i - 1
			end 
		end
	end
	toggle_menu()
end

function toggle_menu_off()
    -- Disable
    if menutimer:is_enabled() then
        menutimer:kill()
		remove_keybinds()
        mp.osd_message("", 0)
    end
end

keybindstimer = mp.add_periodic_timer(settings.osd_duration_seconds, remove_keybinds)
keybindstimer:kill()

menutimer = mp.add_periodic_timer(settings.osd_duration_seconds - 1, showmenu)
menutimer:kill()

if not settings.dynamic_binds then
	add_keybinds()
end

-- script message handler
function handlemessage(msg, value)
	if msg == "toggle" then toggle_menu() ; return end
	if msg == "perf" then toggle_menu_perf() ; return end
	if msg == "show" then showmenu() ; return end
	if msg == "toggle-off" then toggle_menu_off() ; return end
end

mp.register_script_message("easymenu", handlemessage)
