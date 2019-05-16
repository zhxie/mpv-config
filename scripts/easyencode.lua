local settings = {
	--osd when navigating in seconds, in fact, affect nothing
	osd_duration_seconds = 10,

	--amount of entries to show before slicing. Optimal value depends on font/video size etc.
	showamount = 16,

	--keybindings force override only while menu is visible
	--allowing you to use common overlapping keybinds
	dynamic_binds = true,

	--playlist display signs, {"prefix", "suffix"}
	cursor_str = {"{\\fnConsolas}>\\h{\\fnArial}", ""},
	non_str = {"{\\fnConsolas}\\h\\h{\\fnArial}", ""},
	--top and bottom if playlist entries are sliced off from display
	menu_sliced_str = {"...", "..."},

	detached_encode = false,
}
require 'mp.options'
read_options(settings, "easyencode")

local utils = require 'mp.utils'
local msg = require 'mp.msg'

--ffmpeg -i a.mkv -vcodec h264 -s 1280x720 -r 59.94 -aspect 4:3  -crf 22 -acodec aac -ar 48000 -b:a 320 a.mp4

cursor = 0
selmenu = 1
execount = 0
encoderesult = ""
propCat = {"Input", "General", "Video", "Audio", "Subtitle", "Output"}
propCatCount = {4, 1, 9, 4, 1, 2}
propCatOrder = {}
for i=1,table.getn(propCatCount),1 do
	if propCatOrder[i-1] == nil then
		propCatOrder[i] = propCatCount[i]
	else
		propCatOrder[i] = propCatOrder[i-1] + propCatCount[i]
	end
end
local opts = {
	time_in = 0,
	time_out = 0,
	preserve_filters = false,
	only_active_tracks = false,

	container = "",

	vn = false, --video main switch
	vcodec = "",
	sws_flags = "",
	r = 0, --fps
	sw = 0, --frame size
	aspect = 0, --aspect rate
	crf_main = true,
	crf = 0,
	bv = 0,
	pass = 0,

	an = false, --audio main switch
	acodec = "",
	ar = 0, --audio sampling rate
	ba = 0,

	sn = false, --sub main switch
}
local optss = {
	container = {"mp4", "mkv", "webm", "gif"},

	vcodec = {"copy", "h264", "gif"},
	sws_flags = {"bilinear", "spline", "lanczos"},
	r = {0},
	sw = {0},
	aspect = {0, 1.33333, 1.77777, 2.4},
	pass = {1, 2},

	acodec = {"copy", "aac", "mp3", "flac"},
	ar = {0, 44100, 48000, 96000, 192000},
	ba = {128, 192, 256, 320},
}
function initOpts()
	opts.time_in = 0
	opts.time_out = mp.get_property_number("duration")
	opts.preserve_filters = false
	opts.only_active_tracks = false

	opts.container = "mp4"

	opts.vn = true
	opts.vcodec = "copy" --mp.get_property("video-format")
	opts.sws_flags = "spline"
	opts.r = 0 --mp.get_property_number("container-fps")
	optss.r = {0}
	if mp.get_property_number("container-fps") ~= nil then
		if mp.get_property_number("container-fps") > 11 then
			temp = mp.get_property_number("container-fps") / 2
			i = 2
			while temp > 11 do
				optss.r[i] = temp
				i = i + 1
				temp = temp / 2
			end
		end
	end
	opts.sw = 0 --mp.get_property_number("video-params/w")
	optss.sw = {0}
	if mp.get_property_number("video-params/w") ~= nil then
		if mp.get_property_number("video-params/w") >= 480 then
			optss.sw[2] = 480
		end
		if mp.get_property_number("video-params/w") >= 640 then
			optss.sw[3] = 640
		end
		if mp.get_property_number("video-params/w") >= 960 then
			optss.sw[4] = 960
		end
		if mp.get_property_number("video-params/w") >= 1280 then
			optss.sw[5] = 1280
		end
		if mp.get_property_number("video-params/w") >= 1920 then
			optss.sw[6] = 1920
		end
		if mp.get_property_number("video-params/w") >= 2560 then
			optss.sw[7] = 2560
		end
		if mp.get_property_number("video-params/w") >= 3840 then
			optss.sw[8] = 3840
		end
	end
	opts.aspect = 0 --mp.get_property_number("video-params/aspect")
	opts.crf_main = true
	opts.crf = 8
	opts.bv = 8000
	opts.pass = 1

	opts.an = true
	opts.acodec = "copy" --mp.get_property("audio-codec-name")
	opts.ar = 0 --mp.get_property_number("audio-params/samplerate")
	opts.ba = 320

	opts.sn = true
end
propName = {"Timestamp In", "Timestamp Out", "Preserve Filters", "Only Active Tracks",
			"Container", 
			"Video Encoding", "Video Codec", "Scaler", "FPS", "Resolution", "Aspect Ratio", "CRF", "Video Bitrate", "Pass",
			"Audio Encoding", "Audio Codec", "Sampling Rate", "Audio Bitrate",
			"Subtitle Encoding",
			"Generate Encoding Script", "{\\fnSegoe UI Symbol}⚠{\\fnArial} Start Encoding"}
function getPropValue(name, type)
	if name == "Timestamp In" then
		if type == 0 then
			return opts.time_in
		else
			return tostring(sec2time(opts.time_in))
		end
	elseif name == "Timestamp Out" then
		if type == 0 then
			return opts.time_out
		else
			return tostring(sec2time(opts.time_out)) .. " (" .. tostring(sec2time_acc(opts.time_out - opts.time_in)) .. ")"
		end
	elseif name == "Preserve Filters" then
		if type == 0 then
			return opts.preserve_filters
		else
			return btostring(opts.preserve_filters)
		end
	elseif name == "Only Active Tracks" then
		if type == 0 then
			return opts.only_active_tracks
		else
			return btostring(opts.only_active_tracks)
		end
	elseif name == "Container" then
		return opts.container
	elseif name == "Video Encoding" then
		if type == 0 then
			return opts.vn
		else
			return btostring(opts.vn)
		end
	elseif name == "Video Codec" then
		if type == 0 then
			return opts.vcodec
		else
			if opts.vcodec == "copy" then
				if mp.get_property("video-format") ~=nil then
					return opts.vcodec .. " (".. mp.get_property("video-format") ..")"
				else
					return opts.vcodec .. " (und)"
				end
			else
				return opts.vcodec
			end
		end
	elseif name == "Scaler" then
		return opts.sws_flags
	elseif name == "FPS" then
		if type == 0 then
			return opts.r
		else
			if opts.r == 0 then
				if mp.get_property("container-fps") ~= nil then
					return "original" .. " (" .. tostring(string.format("%.2f", mp.get_property_number("container-fps"))) .. ")"
				else
					return "original" .. " (und)"
				end
			else
				return tostring(string.format("%.2f", opts.r))
			end
		end
	elseif name == "Resolution" then
		if type == 0 then
			return opts.sw
		else
			if opts.aspect == 0 then
				if mp.get_property_number("video-params/aspect") ~= nil then
					asp = mp.get_property_number("video-params/aspect")
				else
					asp = 1.77777
				end
			else
				asp = opts.aspect
			end
			if opts.sw == 0 then
				if mp.get_property("video-params/w") ~= nil then
					if opts.aspect == 0 then
						return "original" .. " (" .. tostring(string.format("%d", mp.get_property_number("video-params/w"))) .. " x " .. tostring(string.format("%d", mp.get_property_number("video-params/w") / asp)) .. ")"
					else
						return tostring(string.format("%d", mp.get_property_number("video-params/w"))) .. " x " .. tostring(string.format("%d", mp.get_property_number("video-params/w") / asp))
					end
				else
					return "original" .. " (und)"
				end
			else
				return tostring(string.format("%d", opts.sw)) .. " x " .. tostring(string.format("%d", opts.sw / asp))
			end
		end
	elseif name == "Aspect Ratio" then
		if type == 0 then
			return opts.aspect
		else
			if opts.aspect == 0 then
				if mp.get_property("video-params/aspect") ~= nil then
					return "original" .. " (" .. tostring(string.format("%.4f", mp.get_property_number("video-params/aspect"))) .. ")"
				else
					return "original" .. " (1.7778)"
				end
			else
				return tostring(string.format("%.4f", opts.aspect))
			end
		end
	elseif name == "CRF" then
		if type == 0 then
			return opts.crf
		else
			return tostring(string.format("%.1f", opts.crf))
		end
	elseif name == "Video Bitrate" then
		if type == 0 then
			return opts.bv
		else
			return tostring(opts.bv).." kbps"
		end
	elseif name == "Pass" then
		if type == 0 then
			return opts.pass
		else
			return tostring(opts.pass)
		end
	elseif name == "Audio Encoding" then
		if type == 0 then
			return opts.an
		else
			return btostring(opts.an)
		end
	elseif name == "Audio Codec" then
		if type == 0 then
			return opts.acodec
		else
			if opts.acodec == "copy" then
				if mp.get_property("audio-codec-name") ~= nil then
					return opts.acodec .. " (".. mp.get_property("audio-codec-name") ..")"
				else
					return opts.acodec .. " (und)"
				end
			else
				return opts.acodec
			end
		end
	elseif name == "Sampling Rate" then
		if type == 0 then
			return opts.ar
		else
			if opts.ar == 0 then
				if mp.get_property_number("audio-params/samplerate") ~= nil then
					return "original" .. " (" .. tostring(mp.get_property_number("audio-params/samplerate")).." Hz" .. ")"
				else
					return "original" .. " (und)"
				end
			else
				return tostring(opts.ar).." Hz"
			end
		end
	elseif name == "Audio Bitrate" then
		if type == 0 then
			return opts.ba
		else
			return tostring(opts.ba).." kbps"
		end
	elseif name == "Subtitle Encoding" then
		if type == 0 then
			return opts.sn
		else
			return btostring(opts.sn)
		end
	elseif name == "Generate Encoding Script" then
		return ""
	elseif name == "{\\fnSegoe UI Symbol}⚠{\\fnArial} Start Encoding" then
		if execount == 0 then
			return ""
		else
			return "(Press Again to Start Encoding)"
		end
	else
		return ""
	end
end

function modifyPropValue(name, type)
	if type == 1 then
		delta = -1
	else
		delta = 1
	end
	if name == "Timestamp In" then
		opts.time_in = mp.get_property_number("time-pos")
		if opts.time_out < opts.time_in then
			opts.time_out = mp.get_property_number("duration")
		end
	elseif name == "Timestamp Out" then
		opts.time_out = mp.get_property_number("time-pos")
		if opts.time_in > opts.time_out then
			opts.time_in = 0
		end
	elseif name == "Preserve Filters" then
		if getPropValue(name , 0) then
			opts.preserve_filters = false
		else
			opts.preserve_filters = true
		end
	elseif name == "Only Active Tracks" then
		if getPropValue(name , 0) then
			opts.only_active_tracks = false
		else
			opts.only_active_tracks = true
		end
	elseif name == "Container" then
		for i=1,table.getn(optss.container),1 do
			if getPropValue(name , 0) == optss.container[i] then
				opts.container = optss.container[arraybound(i + delta, table.getn(optss.container))]
				break
			end
		end
		if opts.container == "gif" then
			opts.vcodec = "gif"
			opts.an = false
		else
			if opts.vcodec == "gif" then
				opts.vcodec = "copy"
			end
		end
	elseif name == "Video Encoding" then
		if getPropValue(name , 0) then
			opts.vn = false
		else
			opts.vn = true
		end
	elseif name == "Video Codec" then
		for i=1,table.getn(optss.vcodec),1 do
			if getPropValue(name , 0) == optss.vcodec[i] then
				opts.vcodec = optss.vcodec[arraybound(i + delta, table.getn(optss.vcodec))]
				break
			end
		end
		if opts.vcodec == "gif" then
			opts.container = "gif"
			opts.an = false
		else
			if opts.container == "gif" then
				opts.container = "mp4"
			end
		end
	elseif name == "Scaler" then
		for i=1,table.getn(optss.sws_flags),1 do
			if getPropValue(name , 0) == optss.sws_flags[i] then
				opts.sws_flags = optss.sws_flags[arraybound(i + delta, table.getn(optss.sws_flags))]
				break
			end
		end
	elseif name == "FPS" then
		for i=1,table.getn(optss.r),1 do
			if getPropValue(name , 0) == optss.r[i] then
				opts.r = optss.r[arraybound(i + delta, table.getn(optss.r))]
				break
			end
		end
	elseif name == "Resolution" then
		for i=1,table.getn(optss.sw),1 do
			if getPropValue(name , 0) == optss.sw[i] then
				opts.sw = optss.sw[arraybound(i + delta, table.getn(optss.sw))]
				break
			end
		end
	elseif name == "Aspect Ratio" then
		for i=1,table.getn(optss.aspect),1 do
			if getPropValue(name , 0) == optss.aspect[i] then
				opts.aspect = optss.aspect[arraybound(i + delta, table.getn(optss.aspect))]
				break
			end
		end
	elseif name == "CRF" then
		opts.crf = math.max(opts.crf + 0.5 * delta, 1)
		opts.crf_main = true
	elseif name == "Video Bitrate" then
		opts.bv = math.max(opts.bv + 100 * delta, 100)
		opts.crf_main = false
	elseif name == "Pass" then
		for i=1,table.getn(optss.pass),1 do
			if getPropValue(name , 0) == optss.pass[i] then
				opts.pass = optss.pass[arraybound(i + delta, table.getn(optss.pass))]
				break
			end
		end
		opts.crf_main = false
	elseif name == "Audio Encoding" then
		if getPropValue(name, 0) then
			opts.an = false
		else
			opts.an = true
			if opts.container == "gif" or opts.vcodec == "gif" then
				opts.container = "mp4"
				opts.vcodec = "copy"
			end
		end
	elseif name == "Audio Codec" then
		for i=1,table.getn(optss.acodec),1 do
			if getPropValue(name , 0) == optss.acodec[i] then
				opts.acodec = optss.acodec[arraybound(i + delta, table.getn(optss.acodec))]
				break
			end
		end
	elseif name == "Sampling Rate" then
		for i=1,table.getn(optss.ar),1 do
			if getPropValue(name , 0) == optss.ar[i] then
				opts.ar = optss.ar[arraybound(i + delta, table.getn(optss.ar))]
				break
			end
		end
	elseif name == "Audio Bitrate" then
		for i=1,table.getn(optss.ba),1 do
			if getPropValue(name , 0) == optss.ba[i] then
				opts.ba = optss.ba[arraybound(i + delta, table.getn(optss.ba))]
				break
			end
		end
	elseif name == "Subtitle Encoding" then
		if getPropValue(name, 0) then
			opts.sn = false
		else
			opts.sn = true
		end
	elseif name == "Generate Encoding Script" then
		startEncode(1)
	elseif name == "{\\fnSegoe UI Symbol}⚠{\\fnArial} Start Encoding" then
		if execount == 0 then
			execount = execount + 1
		else
			execount = 0
			startEncode(0)
		end
	end
end

function chkEnableProp(input, name)
	prefix = "{\\s1}{\\cCCCCCC}"
	suffix = "{\\s0}{\\cFFFFFF}"
	if name == "Timestamp In" then
		return input
	elseif name == "Timestamp Out" then
		return input
	elseif name == "Preserve Filters" then
		if opts.vn == false or opts.vcodec == "copy" then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Container" then
		return input
	elseif name == "Video Encoding" then
		return input
	elseif name == "Video Codec" then
		if opts.vn == false then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Scaler" then
		if opts.vn == false or opts.vcodec == "copy" or (opts.sw == 0 and opts.aspect == 0) then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "FPS" then
		if opts.vn == false or opts.vcodec == "copy" or opts.r == 0 then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Resolution" then
		if opts.vn == false or opts.vcodec == "copy" or (opts.sw == 0 and opts.aspect == 0) then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Aspect Ratio" then
		if opts.vn == false or opts.vcodec == "copy" or opts.aspect == 0 then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "CRF" then
		if opts.vn == false or opts.vcodec == "copy" or opts.vcodec == "gif" or opts.crf_main == false then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Video Bitrate" then
		if opts.vn == false or opts.vcodec == "copy" or opts.vcodec == "gif" or opts.crf_main == true then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Pass" then
		if opts.vn == false or opts.vcodec == "copy" or opts.vcodec == "gif" or opts.crf_main == true then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Audio Encoding" then
		return input
	elseif name == "Audio Codec" then
		if opts.an == false then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Sampling Rate" then
		if opts.an == false or opts.acodec == "copy" or opts.ar == 0 then
			return prefix .. input .. suffix
		else
			return input
		end
	elseif name == "Audio Bitrate" then
		if opts.an == false or opts.acodec == "copy" or opts.acodec == "flac" then
			return prefix .. input .. suffix
		else
			return input
		end
	else
		return input
	end
end

function getEncodeString(type)
	if type <= 0 then
		str = "-i " .. mp.get_property("path") .. " "
	else
		str = ""
	end
	if type <= 1 then
		str = str .. "-ss " .. tostring(opts.time_in) .. " -to " .. tostring(opts.time_out + 1 / mp.get_property_number("container-fps") / 2) .. " "
	else
		str = ""
	end
	if opts.only_active_tracks == false then
		str = str .. "-map 0 "
	else
		str = str .. getActiveTracks() .. " "
	end
	if opts.vn == false then
		str = str .. "-vn "
	else
		str = str .. "-c:v " .. opts.vcodec .. " "
		if opts.vcodec ~= "copy" then
			if opts.r ~= 0 then
				str = str .. "-r " .. tostring(string.format("%.2f", opts.r)) .. " "
			end
			if opts.sw ~= 0 or opts.aspect ~= 0 then
				if opts.aspect == 0 then
					asp = mp.get_property_number("video-params/aspect")
				else
					asp = opts.aspect
				end
				str = str .. "-s " .. tostring(string.format("%d", opts.sw)) .. "x" .. tostring(string.format("%d", opts.sw / asp)) .. " "
				str = str .. "-sws_flags " .. opts.sws_flags .. " "
			end
			if opts.aspect ~= 0 then
				str = str .. "-aspect " .. opts.aspect .. " "
			end
			if opts.vcodec ~= "gif" then
				if opts.crf_main == true then
					str = str .. "-crf " .. opts.crf .. " "
				else
					str = str .. "-b:v " .. opts.bv .. "k "
					str = str .. "-pass " .. opts.pass .. " "
				end
			end
			if opts.preserve_filters == true then
				filters = getFilters()
				if filters ~= "" then
					str = str .. "-filter:v '" .. filters .. "' "
				end
			end
		end
	end
	if opts.an == false then
		str = str .. "-an "
	else
		str = str .. "-c:a " .. opts.acodec .. " "
		if opts.acodec ~= "copy" then
			if opts.ar ~= 0 then
				str = str .. "-ar " .. opts.ar .. " "
			end
			if opts.acodec ~= "flac" then
				str = str .. "-b:a " .. opts.ba .. "k "
			end
		end
	end
	if opts.sn == false then
		str = str .. "-sn "
	end
	if type <= 0 then
		str = str .. mp.get_property("path") .. "." .. opts.container
	end
	return str
end

function showmenu(duration)
    if not mp.get_property("path") then
        mp.osd_message("No file currently playing")
        return
    end
    if not mp.get_property_bool("seekable") then
        mp.osd_message("Cannot encode non-seekable media")
        return
    end

	if opts.time_out == 0 then
		initOpts()
	end
	plen = table.getn(propName)
	if plen == 0 then return end
	add_keybinds()
	output = "{\\fs10}{\\bord0.8}{\\b1}Playing: {\\b0}"..mp.get_property('media-title').."\n\n"
	for i=1,table.getn(propCat),1 do
		if(cursor < propCatOrder[i]) then
			selmenu = i
			break
		end
	end
	propCatOrder[0] = 0
	output = output.."{\\b1}Encode - " .. propCat[selmenu] .. " - " .. (cursor+1) - propCatOrder[selmenu-1] .. " / " .. propCatOrder[selmenu] - propCatOrder[selmenu-1] .. "{\\b0}\n"
	local b = cursor - math.floor(settings.showamount/2)
	local showall = false
	local showrest = false
	if b<0 then b=0 end
	if plen <= settings.showamount then
		b=0
		showall=true
	end
	if b > math.max(plen-settings.showamount-1, 0) then
		b=plen-settings.showamount
		showrest=true
	end
	if b > 0 and not showall then output=output..settings.menu_sliced_str[1].."\n" end

	for a=b,b+settings.showamount-1,1 do
		if a == plen then break end
		isbold = false
		if a<propCatOrder[selmenu] and a>=propCatOrder[selmenu-1] then isbold = true end
		temp = getPropValue(propName[a+1])
		if temp == "" then
			temp = propName[a+1]
		else
			temp = propName[a+1] ..": "..temp
			temp = chkEnableProp(temp, propName[a+1])
		end
		if a ~= cursor and isbold == false then output = output..settings.non_str[1]..temp..settings.non_str[2].."\n" end
		if a == cursor and isbold == false then output = output..settings.cursor_str[1]..temp..settings.cursor_str[2].."\n" end
		if a ~= cursor and isbold == true then output = output.."{\\b1}"..settings.non_str[1]..temp..settings.non_str[2].."{\\b0}\n" end
		if a == cursor and isbold == true then output = output.."{\\b1}"..settings.cursor_str[1]..temp..settings.cursor_str[2].."{\\b0}\n" end
		if a == b+settings.showamount-1 and not showall and not showrest then
			output=output..settings.menu_sliced_str[2]
		end
	end

	output = output .. "\n{\\b1}FFmpeg: {\\b0}" .. getEncodeString(1)
	if encoderesult ~= "" then
		output = output .. "\n\n{\\b1}Result: {\\b0}" .. encoderesult
	end

	mp.osd_message(mp.get_property("osd-ass-cc/0") .. output .. mp.get_property("osd-ass-cc/1"), (tonumber(duration) or settings.osd_duration_seconds))

	if not menutimer:is_enabled() then
		keybindstimer:kill()
		keybindstimer:resume()
	end
end

function startEncode(type)
	local args = {
        "ffmpeg", "-stats",
		"-loglevel", "panic", "-hide_banner", --stfu ffmpeg
		"-ss", tostring(opts.time_in),
		"-i", mp.get_property("path"),
		"-to", tostring(opts.time_out - opts.time_in + 1 / mp.get_property_number("container-fps") / 2),
		--"-n",
	}
	local args_gen = {
		"cmd", "/c", "echo",
		"start", "ffmpeg.exe", "-stats",
		"-loglevel", "panic", "-hide_banner",
		"-ss", tostring(opts.time_in),
		"-i", mp.get_property("path"),
		"-to", tostring(opts.time_out - opts.time_in + 1 / mp.get_property_number("container-fps") / 2),
	}

	for token in string.gmatch(getEncodeString(2), "[^%s]+") do
		args[#args + 1] = token
		args_gen[#args_gen + 1] = token
	end
	args[#args + 1] = mp.get_property("path") .. "." .. opts.container
	args_gen[#args_gen + 1] = mp.get_property("path") .. "." .. opts.container
	args_gen[#args_gen + 1] = ">%USERPROFILE%\\Desktop\\ffmpeg.bat"

	if type == 1 then
		local res_gen = utils.subprocess({ args = args_gen, max_size = 0, cancellable = false })
		if res_gen.status == 0 then
			encoderesult = "Generated encoding script succesfully, please check your desktop."
		else
			encoderesult = "Failed to generate encoding script."
		end
		showmenu()
	else
		if settings.detached_encode then
			encoderesult = "Encoding progress is pass to FFmpeg."
			utils.subprocess_detached({ args = args })
		else
			encoderesult = "Encoding..."
			local res = utils.subprocess({ args = args, max_size = 0, cancellable = false })
			if res.status == 0 then
				encoderesult = "Finished encoding succesfully."
			else
				encoderesult = "Failed to encode, please check the log."
			end
			showmenu()
		end
	end
end

function getFilters() -- modified to compact mpv 0.28.0
    filters = ""
    for _, vf in ipairs(mp.get_property_native("vf")) do
		local name = vf["name"]
		local filter
		if name == "lavfi" then
			local p = vf["params"]
			filter = p["graph"]
		end

        --[[if name == "crop" then
            local p = vf["params"]
            filter = string.format("crop=%d:%d:%d:%d", p["w"], p["h"], p["x"], p["y"])
        elseif name == "mirror" then
            filter = "hflip"
        elseif name == "flip" then
            filter = "vflip"
		end]]--
		filters = concatstr(filters, filter)
	end

	local rot = mp.get_property_number("video-rotate")
	if rot == 90 then
		filters = concatstr(filters, string.format("transpose=clock"))
	elseif rot == 180 then
		filters = concatstr(filters, string.format("transpose=clock,transpose=clock"))
	elseif rot == 270 then
		filters = concatstr(filters, string.format("transpose=cclock"))
	end

    return filters
end

function getActiveTracks()
    local tracks = mp.get_property_native("track-list")
    local accepted = {
        video = true,
        audio = not mp.get_property_bool("mute"),
        sub = mp.get_property_bool("sub-visibility")
    }
    local active_tracks = {}
    for _, track in ipairs(tracks) do
        if track["selected"] and (not track["external"]) and accepted[track["type"]] then
            active_tracks[#active_tracks + 1] = string.format("0:%d", track["ff-index"])
        end
	end
	local active_tracks_str = ""
	for i=1,table.getn(active_tracks),1 do
		if active_tracks_str ~= "" then
			active_tracks_str = active_tracks_str .. " "
		end
		active_tracks_str = active_tracks_str .. "-map " .. active_tracks[i]
	end
    return active_tracks_str
end

function btostring(boo)
	if boo == true then
		return "yes"
	else
		return "no"
	end
end

function sec2time(sec)
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

function sec2time_acc(sec)
	t_hour = 0
	t_min = 0
	t_sec = 0
	t_frame = 0

	if tonumber(sec) == nil then
		return "no"
	else
		frame = sec - math.floor(tonumber(sec))
		sec = math.floor(tonumber(sec))
	end

	t_sec = sec % 60
	t_min = math.floor((sec - t_sec) / 60)
	t_hour = sec - 60 * t_min - t_sec
	t_frame = math.floor(frame / (1 / mp.get_property_number("container-fps")))

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

	return s_hour..":"..s_min..":"..s_sec .. "+" .. t_frame
end

function arraybound(order, arrayn)
	if order > arrayn then
		temp = order - arrayn
	elseif order < 1 then
		temp = order + arrayn
	else
		temp = order
	end
	return temp
end

function concatstr(tomoya, eriri)
	if tomoya == "" then
		tomoya = eriri
	else
		tomoya = tomoya .. "," .. eriri
	end
	return tomoya
end

function modifyprop()
	if plen == 0 then return end
	modifyPropValue(propName[cursor+1])
	showmenu()
end

function modifyprop2()
	if plen == 0 then return end
	modifyPropValue(propName[cursor+1], 1)
	showmenu()
end

function moveup()
	execount = 0
	if plen == 0 then return end
	if cursor ~= 0 then
		cursor = cursor - 1
	else
		cursor = plen - 1
	end
	showmenu()
end

function movedown()
	execount = 0
	if plen == 0 then return end
	if cursor ~= plen-1 then
		cursor = cursor + 1
	else
		cursor = 0
	end
	showmenu()
end

function add_keybinds()
	mp.add_forced_key_binding('UP', 'moveup', moveup, "repeatable")
	mp.add_forced_key_binding('DOWN', 'movedown', movedown, "repeatable")
	mp.add_forced_key_binding('ENTER', 'modifyprop', modifyprop, "repeatable")
	mp.add_forced_key_binding('SHIFT+ENTER', 'modifyprop2', modifyprop2, "repeatable")
end

function remove_keybinds()
	if settings.dynamic_binds then
		mp.remove_key_binding('moveup')
		mp.remove_key_binding('movedown')
		mp.remove_key_binding('modifyprop')
		mp.remove_key_binding('modifyprop2')
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

--script message handler
function handlemessage(msg, value)
	if msg == "toggle" then toggle_menu() ; return end
	if msg == "show" then showmenu() ; return end
	if msg == "toggle-off" then toggle_menu_off() ; return end
end

mp.register_script_message("easyencode", handlemessage)
