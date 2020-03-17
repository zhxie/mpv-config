-- allows mpv using customize osd playing msg

local replace_def_playing_msg = true
local msg_showed = false

local function clear_msg()
    if msg_showed ~= true then
    end
end

local function replace_msg()
    if msg_showed ~= true then
        local output = ""

        if mp.get_property_number("playlist-count") ~= 1 then
            output = output .. "[" .. mp.get_property("playlist-pos-1") .. "/" .. mp.get_property("playlist-count") .. "]"
        end
        output = output .. " " .. mp.get_property("media-title") .. " "
        if mp.get_property("hwdec-current") ~= "no" then
            output = output .. "[HW]"
        end
        output = output .. "\n"

        if counttype("audio") > 1 then
            output = output .. "{\\fs10}{\\bord0.8}　♬ " .. travtype("audio") .. "\n{\\r}"
        end

        if mp.get_property("sub") ~= "no" then
            output = output .. "{\\fs10}{\\bord0.8}　{\\fnSegoe UI Symbol}💬{\\fnArial} " .. travtype("sub") .. "\n{\\r}"
        end

        --if mp.get_property("audio") ~= "no"
        output = output .. "▶ " .. formattime(mp.get_property_number("time-pos")) .. " / " .. formattime(mp.get_property_number("duration"))
        if mp.get_property_number("percent-pos") then
            output = output .. " (" .. math.floor(mp.get_property_number("percent-pos")) .. "%)"
        end

        mp.set_property_native("osd-playing-msg", "")
        mp.osd_message(mp.get_property("osd-ass-cc/0")..output)
        msg_showed = true
    end
end

function travtrack(type, id)
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

function counttype(type)
    local count = 0
    for i=0,mp.get_property("track-list/count"),1 do
        if mp.get_property("track-list/"..i.."/type") == type then
            count = count + 1
        end
    end
    return count
end

function travtype(type)
	return travtrack(type, mp.get_property(type))
end

function formattime(clock_f)
    local hour, min, sec
    local clock_s

    hour = math.floor(clock_f / 3600)
    clock_f = clock_f - 3600 * hour
    min = math.floor(clock_f / 60)
    clock_f = clock_f - 60 * min
    sec = math.floor(clock_f)

    if hour < 10 then
        if hour == 0 then
            clock_s = "00"
        else
            clock_s = "0" .. hour
        end
    else
        clock_s = "" .. hour
    end
    clock_s = clock_s .. ":"
    if min < 10 then
        if min == 0 then
            clock_s = clock_s .. "00"
        else
            clock_s = clock_s .. "0" .. min
        end
    else
        clock_s = clock_s .. min
    end
    clock_s = clock_s .. ":"
    if sec < 10 then
        if sec == 0 then
            clock_s = clock_s .. "00"
        else
            clock_s = clock_s .. "0" .. sec
        end
    else
        clock_s = clock_s .. sec
    end

    return clock_s
end

function round(number)
    local int, float
    int, float = math.modf(number)
    if float > 0.5 then
        int = int + 1
    end
    return int
end

if replace_def_playing_msg then
    --mp.register_event("start-file", clear_msg)
    mp.register_event("playback-restart", replace_msg)
    mp.register_event("file-loaded", function() msg_showed = false end)
    mp.register_event("idle", function() msg_showed = false end)
end