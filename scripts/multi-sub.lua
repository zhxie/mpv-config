local msg = require 'mp.msg'
local options = require 'mp.options'
local utils = require 'mp.utils'

function get_sub_count()
    local tracks = mp.get_property_number("track-list/count")
    local count = 0;
    for i = 0, tracks - 1, 1 do
        local type = mp.get_property("track-list/" .. i .. "/type")
        if (type == "sub") then
            count = count + 1
        end
    end
    return count
end

function get_external_sub_count()
    local tracks = mp.get_property_number("track-list/count")
    local count = 0;
    for i = 0, tracks - 1, 1 do
        local type = mp.get_property("track-list/" .. i .. "/type")
        local external = mp.get_property("track-list/" .. i .. "/external")
        if (type == "sub" and external == "yes") then
            count = count + 1
        end
    end
    return count
end

function get_external_sub_filename()
    local tracks = mp.get_property_number("track-list/count")
    local count = 0;
    local filenames = {}
    for i = 0, tracks - 1, 1 do
        local type = mp.get_property("track-list/" .. i .. "/type")
        local external = mp.get_property("track-list/" .. i .. "/external")
        if (type == "sub" and external == "yes") then
            count = count + 1
            filenames[count] = mp.get_property("track-list/" .. i .. "/external-filename"):gsub("\\", "/")
        end
    end
    return filenames
end

function set_multi_sub(id)
    id = id or 1
    local filenames = get_external_sub_filename()
    local count = table.getn(filenames)
    if (id > count) then
        return
    end
    mp.command("vf toggle subtitles=" .. filenames[id])
end

mp.register_script_message("multi_sub", set_multi_sub)
