-- Use MediaInfo to display the information of media

utils = require 'mp.utils'

function mediainfo()
    local was_ontop = mp.get_property_native("ontop")
    if was_ontop then mp.set_property_native("ontop", false) end
    local was_pause = mp.get_property_native("pause")
    if not was_pause then mp.set_property_native("pause", true) end

    local path = mp.get_property("path")
    --local file = mp.get_property_osd("filename")..".txt"
	local res = utils.subprocess({
        args = {"MediaInfo.exe", path, "--Output=HTML", "--logfile="..os.getenv("TEMP").."\\MediaInfo.html"},
    })
    local res2 = utils.subprocess({
        args = {"cmd", "/c", os.getenv("TEMP").."\\MediaInfo.html"}
    })

    if was_ontop then mp.set_property_native("ontop", true) end
    if not was_pause then mp.set_property_native("pause", false) end
    if (res2.status ~= 0) then
        return
    end
end

mp.add_key_binding('i', 'mediainfo', mediainfo)
