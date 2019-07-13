local settings = {
    required_ver = "mpv 0.29.0",
    update_date = "2019-07-13",
    mpv_prefix = "{\\fs10}{\\bord0.8}{\\b1}",
    mpv_suffix = "{\\b0}",
    warn_prefix = {
        "{\\i1}", "{\\i1}{\\bord0.5}{\\3c&H00DDDD&}", "{\\i1}{\\bord0.5}{\\3c&H0000FF&}",
    },
    warn_suffix = "{\\i0}{\\bord0.8}{\\3c&H%s&}",
    script_prefix = "{\\b1}",
    script_suffix = "{\\b0}",
    ascii_prefix = "{\\fnConsolas}",
    ascii_suffix = "{\\fnArial}",
}

local utils = require 'mp.utils'

function show_info()
    output = "{\\fs10}{\\bord0.8}　\n"
    output = attach_ascii(output, "                     --   --                    ")
    output = attach_ascii(output, "               -  :+ssssooossy/:`-              ")
    output = attach_ascii(output, "           -  /osyyyyyyyyysyyyyysoy:`           ")
    output = attach_ascii(output, "         - `ssyyyyysoohooooooooossysoy`         ")
    output = attach_ascii(output, "       - -ssyyyysohoooooooooooooooosssoy`       ")
    output = attach_ascii(output, "      - .oyyyysoooooooooooooooooooooossso.-     ")
    output = attach_ascii(output, "     - /oyyyyshooohho+.:::/yhhoooooooossso.-    ")
    output = attach_ascii(output, "    ` .oyyyyshooho`  -------  +hooooooossso.-   " .. settings.mpv_prefix .. attach_ascii_tail(mp.get_property("mpv-version"), 55) .. settings.mpv_suffix)
    output = attach_ascii(output, "   - -syyyysoooh.  ---  --------shooooossssy:   ")
    output = attach_ascii(output, "   ` :oyyyysooh. -- -yoy:  -`-```sooososssso/-  ")
    output = attach_ascii(output, "   - /syyyysohs- ----ysysos/`-```/oosossssso/`  ")
    output = attach_ascii(output, "   - .oyyyysohs- ----ysssohy.````/oosossssso/`  ")
    output = attach_ascii(output, "   ` :syyyyyooh. ---`sho/` -```:`yososssssso.-  " .. attach_ascii_tail("config by {\\b1}Sketch{\\b0} with love", 55, 10))
    output = attach_ascii(output, "   `  +sysyysooh: --`:--``````:`yoossssssoo+:   ")
    if mp.get_property("mpv-version") ~= settings.required_ver then
        output = attach_ascii(output, settings.warn_prefix[1] .. attach_ascii_tail(settings.required_ver .. " is preferred, or may not support scripts.", 55) .. settings.warn_suffix, "")
    end
    output = attach_ascii(output, "    : -ssssssssohs`-```````:``/oossssssosos``   ")
    output = attach_ascii(output, "     ` -sssssssssshhy/.:::.+soosssssssssoo-:    ")
    output = attach_ascii(output, "      :  yosssssssssssoooosssssssssossshy-:     ")
    output = attach_ascii(output, "       :  `sossssssssssssssssssssssssho``-      " .. attach_ascii_tail("{\\b1}mpv{\\b0} has accompanied you waching for " .. total_time() .. ".", 55, 10))
    output = attach_ascii(output, "         :  -+osssssssssssssssssssohy--`        " .. attach_ascii_tail(settings.update_date, 55))
    output = attach_ascii(output, "           :`  `/sooosssssssoooho+` :-          ")
    output = attach_ascii(output, "              ::-   `:.////.:`  `.`             ")
    output = attach_ascii(output, "                  -`:.......:`                  ")

    mp.osd_message(mp.get_property("osd-ass-cc/0") .. output .. mp.get_property("osd-ass-cc/1"))
end

function attach_warn(sentence, word, level)
    return sentence .. settings.warn_prefix[level or 1] .. "\n　" .. word .. settings.warn_suffix
end

function attach_script(sentence, word, time)
    return sentence .. "\n　" .. settings.script_prefix .. word .. settings.script_suffix .. " (last updated at " .. time .. ")"
end

function attach_ascii(sentence, word, head)
    head = head or "\n　"
    return sentence .. settings.ascii_prefix .. head .. word .. settings.ascii_suffix
end

function attach_ascii_tail(word, length, escape)
    local word_length = string.len(word) - (escape or 0)
    local blank_length = math.floor((length - word_length) / 2)
    local str = ""
    for i=1,blank_length,1 do
        str = str .. " "
    end
    return str .. word
end

-- timelogger related --
-- To set another path for the logfile, please uncomment one of the linues below
-- local logpath = "C:\Users\user\AppData\Roaming\mpv\time.log"
-- local logpath = "/home/user/.config/mpv/time.log"

-- Set to true to disply the time in days, hours, min and sec (instead of hours, min, sec)
local timeformatindays = false

-- automaticly sets the logpath
function detect_logpath()
    if (logpath ~= nil) or (logpath == "") then return end
    logpath = utils.join_path(mp.find_config_file("."), "time.log")
end

-- helper for time_format returns reduced time, string
function time_format_helper(time, divider, suffix)
    if time >= divider then
        if math.floor(time / divider) <10 then
            return math.mod(time, divider), ("0" .. math.floor(time / divider) .. suffix .. "")
        else
            return math.mod(time, divider), (math.floor(time / divider) .. suffix .. "")
        end
    end
    return time, ""
end

-- transforms the time from s to (days), hours, min, sec
function time_format(time)
    local s = ""
    local start = 1
    local times = {86400, 3600, 60, 1}
    local suffixes = {":", ":", ":", ""}
    if not timeformatindays then start = 2 end
    for i = start, 4, 1 do
        time, string = time_format_helper(time, times[i], suffixes[i])
        s = s .. string
    end
    return s
end

-- checks if there are file problems
function file_exists(path)
    local f, err = io.open(path, "a")
    if f == nil then
        mp.osd_message("timelogger - Error opening file, error: " .. err)
        mp.msg.error("Error opening file, error: " .. err)
        return false
    end
    f:close()
    return true
end

-- displays total time
function total_time()
    if not file_exists then return nil end
    local total = 0
    for line in io.lines(logpath) do
        local s1, s2 = string.match(line, "(.-)s,(.*)") -- non-greedy matching in lua is "-"
        total = total + tonumber(s1)
    end
    return time_format(total)
end

detect_logpath()
mp.add_key_binding('i', 'mpv-update', show_info)