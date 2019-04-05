-- This script logs total time used in mpv
-- The default key to display total watch time is "k"
--
-- This can be overwritten by editing the last line in this script
-- Or add the following to your input.conf to change the default keybinding:
-- KEY script-binding display_total_watch_time

-- To set another path for the logfile, please uncomment one of the linues below
-- local logpath = "C:\Users\user\AppData\Roaming\mpv\time.log"
-- local logpath = "/home/user/.config/mpv/time.log"

local settings = {
    -- Set to true to disply the time in days, hours, min and sec (instead of hours, min, sec)
    timeformatindays = false,

    -- Set to true to disable looging of the filename
    incognito = true
}
require 'mp.options'
read_options(settings, "timelogger")

local utils = require 'mp.utils'

-- automaticly sets the logpath
function detect_logpath()
    if (logpath ~= nil) or (logpath == "") then return end
    logpath = utils.join_path(mp.find_config_file("."), "time.log")
end

-- gets file name and resets values
function on_file_load(event)
    totaltime = 0
    lasttime = os.clock()
    timeloaded = os.date("%c")
    paused = mp.get_property_bool("pause")
    filename = "null"
    if not settings.incognito then filename = mp.get_property("path") end
    file_exists(logpath)
end

-- write to file on pause
function on_pause_change(name, pausing)
    if pausing == true then
        on_file_end()
    else
        on_file_load()
    end
    paused = pausing
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

-- write to file when exiting the player or switching file
function on_file_end(event)
    totaltime = totaltime + os.clock() - lasttime
    if file_exists(logpath) then
        file = io.open(logpath, "a")
        if settings.incognito then
            file:write(totaltime .. "s, " .. timeloaded, "\n")
        else
            file:write(totaltime .. "s, " .. timeloaded .. ", " .. filename, "\n")
        end
        file:close()
    end
end

-- helper for time_format returns reduced time, string
function time_format_helper(time, divider, suffix)
    if time >= divider then
        return math.mod(time, divider), (math.floor(time / divider) .. suffix .. " ")
    end
    return time, ""
end

-- transforms the time from s to (days), hours, min, sec
function time_format(time)
    local s = ""
    local start = 1
    local times = {86400, 3600, 60, 1}
    local suffixes = {"d", "h", "m", "s"}
    if not settings.timeformatindays then start = 2 end
    for i = start, 4, 1 do
        time, string = time_format_helper(time, times[i], suffixes[i])
        s = s .. string
    end
    return s
end

-- displays total time
function total_time()
    if not file_exists then return nil end
    local total = 0
    for line in io.lines(logpath) do
        local s1, s2 = string.match(line, "(.-)s,(.*)") -- non-greedy matching in lua is "-"
        total = total + tonumber(s1)
    end
    total = total + totaltime
    if not paused then total = total + os.clock() - lasttime end
    mp.osd_message("Total logged time: " .. time_format(total))
end

detect_logpath()
mp.register_event("file-loaded", on_file_load)
mp.register_event("end-file", on_file_end)
mp.observe_property("pause", "bool", on_pause_change)
