utils = require 'mp.utils'

function frame_step(input)
    frame_old = mp.get_property_number("estimated-frame-number")
    frame_total = mp.get_property_number("estimated-frame-count")
    if(input == 1) then
        mp.command("frame-step")
    else
        mp.command("frame-back-step")
    end
    frame_now = math.min(math.max(0, frame_old + input), frame_total)
    mp.osd_message("Frame: " .. frame_now .. " / " .. frame_total)
end

function frame_step_forward()
    frame_step(1)
end

function frame_step_backward()
    frame_step(-1)
end

function hotkey_dist()
    local res = utils.subprocess({
        args = {"HotkeyDist.exe"}
    })
end

function switch_hwdec()
    if (mp.get_property("hwdec") == "no") then
        if (mp.get_property("video-format") == "hevc") then
            mp.set_property("hwdec", "auto-copy")
        else
            mp.set_property("hwdec", "auto")
        end
    else
        mp.set_property("hwdec", "no")
    end
    mp.command([[show-text "hwdec: ${hwdec} (${hwdec-current})"]])
end

local force_ontop_when_start = true
local was_ontop_start = false
local function start_ontop()
    if was_ontop_start == false then
        if force_ontop_when_start then
            mp.set_property_native("ontop", true)
        end
        was_ontop_start = true
    end
end

--mp.register_script_message("Frame_Step", frame_step)
mp.add_key_binding('f', 'Frame_Step', frame_step_forward, "repeatable")
mp.add_key_binding('d', 'Frame_Back_Step', frame_step_backward, "repeatable")
mp.add_key_binding('H', 'Hotkey_Dist', hotkey_dist)
mp.add_key_binding('O', 'Switch_Hwdec', switch_hwdec)

mp.register_event("start-file", start_ontop)
