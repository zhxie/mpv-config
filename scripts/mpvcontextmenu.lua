--[[ *************************************************************
 * Menu defintions and script-message registration
 * Thomas Carmichael (carmanaught) https://gitlab.com/carmanaught
 *
 * Used in concert with menu-builder.lua to create a menu. The script-message registration
 * and calling of the createMenu script are done from the definitions here as trying to
 * pass the menu definitions to the menu builder with the script-message register there
 * doesn"t allow for the unloaded/loaded state to work propertly.
 *
 * Specify the menu type in the createMenu function call below. Current options are:
 * tk
 *
 * 2017-08-04 - Version 0.1 - Separation of menu building from definitions.
 * 2017-08-07 - Version 0.2 - Added second mp.register_script_message and changed original
 *                            to allow the use of different menu types by using the related
 *                            script-message name.
 *
 ***************************************************************
--]]
local function mpdebug(x)
    mp.msg.info(x)
end
local propNative = mp.get_property_native

-- Set options
local options = require "mp.options"
local utils = require("mp.utils")
local opt = {
    -- Play > Speed - Percentage
    playSpeed = 5,
    -- Play > Seek - Seconds
    seekSmall = 5,
    seekMedium = 30,
    seekLarge = 60,
    -- Video > Aspect - Percentage
    vidAspect = 0.1,
    -- Video > Zoom - Percentage
    vidZoom = 0.1,
    -- Video > Screen Position - Percentage
    vidPos = 0.1,
    -- Video > Color - Percentage
    vidColor = 1,
    -- Audio > Sync - Milliseconds
    audSync = 100,
    -- Audio > Volume - Percentage
    audVol = 2,
    -- Subtitle > Position - Percentage
    subPos = 1,
    -- Subtitle > Scale - Percentage
    subScale = 1,
    -- Subtitle > Sync
    subSync = 100 -- Milliseconds
}
options.read_options(opt)

-- Set some constant values
local SEP = "separator"
local CASCADE = "cascade"
local COMMAND = "command"
local CHECK = "checkbutton"
local RADIO = "radiobutton"
local AB = "ab-button"

local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- Edition menu functions
local function enableEdition()
    local editionState = false
    if (propNative("edition-list/count") < 1) then
        editionState = true
    end
    return editionState
end

local function checkEdition(editionNum)
    local editionEnable, editionCur = false, propNative("edition")
    if (editionNum == editionCur) then
        editionEnable = true
    end
    return editionEnable
end

local function editionMenu()
    local editionCount = propNative("edition-list/count")
    local editionMenuVal = {}

    if not (editionCount == 0) then
        for editionNum = 0, (editionCount - 1), 1 do
            local editionTitle = propNative("edition-list/" .. editionNum .. "/title")
            if not (editionTitle) then
                editionTitle = "Edition " .. (editionNum + 1)
            end

            local editionCommand = "set edition " .. editionNum
            table.insert(
                editionMenuVal,
                {RADIO, editionTitle, "", editionCommand, function()
                        return checkEdition(editionNum)
                    end, false, true}
            )
        end
    else
        table.insert(editionMenuVal, {COMMAND, "No Editions", "", "", "", true})
    end

    return editionMenuVal
end

-- Chapter menu functions
local function enableChapter()
    local chapterEnable = false
    if (propNative("chapter-list/count") < 1) then
        chapterEnable = true
    end
    return chapterEnable
end

local function checkChapter(chapterNum)
    local chapterState, chapterCur = false, propNative("chapter")
    if (chapterNum == chapterCur) then
        chapterState = true
    end
    return chapterState
end

local function chapterMenu()
    local chapterCount = propNative("chapter-list/count")
    local chapterMenuVal = {}

    chapterMenuVal = {
        {COMMAND, "Previous", "Alt+Left", "add chapter -1", "", false},
        {COMMAND, "Next", "Alt+Right", "add chapter 1", "", false},
        {SEP}
    }
    if not (chapterCount == 0) then
        for chapterNum = 0, (chapterCount - 1), 1 do
            local chapterTitle = propNative("chapter-list/" .. chapterNum .. "/title")
            if not (chapterTitle) then
                chapterTitle = "Chapter " .. (chapterNum + 1)
            end

            local chapterCommand = "set chapter " .. chapterNum
            if (chapterNum == 0) then
                table.insert(chapterMenuVal, {SEP})
            end
            table.insert(
                chapterMenuVal,
                {RADIO, chapterTitle, "", chapterCommand, function()
                        return checkChapter(chapterNum)
                    end, false}
            )
        end
    end

    return chapterMenuVal
end

-- Track type count function to iterate through the track-list and get the number of
-- tracks of the type specified. Types are:  video / audio / sub. This actually
-- returns a table of track numbers of the given type so that the track-list/N/
-- properties can be obtained.

local function trackCount(checkType)
    local tracksCount = propNative("track-list/count")
    local trackCountVal = {}

    if not (tracksCount < 1) then
        for i = 0, (tracksCount - 1), 1 do
            local trackType = propNative("track-list/" .. i .. "/type")
            if (trackType == checkType) then
                table.insert(trackCountVal, i)
            end
        end
    end

    return trackCountVal
end

-- Track check function, to check if a track is selected. This isn"t specific to a set
-- track type and can be used for the video/audio/sub tracks, since they"re all part
-- of the track-list.

local function checkTrack(trackNum)
    local trackState, trackCur = false, propNative("track-list/" .. trackNum .. "/selected")
    if (trackCur == true) then
        trackState = true
    end
    return trackState
end

-- Video > Track menu functions
local function enableVidTrack()
    local vidTrackEnable, vidTracks = false, trackCount("video")
    if (#vidTracks < 1) then
        vidTrackEnable = true
    end
    return vidTrackEnable
end

local function vidTrackMenu()
    local vidTrackMenuVal, vidTrackCount = {}, trackCount("video")

    if not (#vidTrackCount == 0) then
        for i = 1, #vidTrackCount, 1 do
            local vidTrackNum = vidTrackCount[i]
            local vidTrackID = propNative("track-list/" .. vidTrackNum .. "/id")
            local vidTrackTitle = propNative("track-list/" .. vidTrackNum .. "/title")
            if not (vidTrackTitle) then
                vidTrackTitle = "Video Track " .. i
            end

            local vidTrackCommand = "set vid " .. vidTrackID
            if (i == 1) then
                table.insert(
                    vidTrackMenuVal,
                    {RADIO, "Disabled", "", "set vid 0", function()
                            return noneCheck("vid")
                        end, false}
                )
                table.insert(vidTrackMenuVal, {SEP})
            end
            table.insert(
                vidTrackMenuVal,
                {RADIO, vidTrackTitle, "", vidTrackCommand, function()
                        return checkTrack(vidTrackNum)
                    end, false}
            )
        end
    end

    return vidTrackMenuVal
end

function noneCheck(checkType)
    local checkVal, trackID = false, propNative(checkType)
    if (type(trackID) == "boolean") then
        if (trackID == false) then
            checkVal = true
        end
    end
    return checkVal
end

-- Audio > Track menu functions
local function enableAudTrack()
    local audTrackEnable, audTracks = false, trackCount("audio")
    if (#audTracks < 1) then
        audTrackEnable = true
    end
    return audTrackEnable
end

local function audTrackMenu()
    local audTrackMenuVal, audTrackCount = {}, trackCount("audio")

    audTrackMenuVal = {}
    if not (#audTrackCount == 0) then
        for i = 1, (#audTrackCount), 1 do
            local audTrackNum = audTrackCount[i]
            local audTrackID = propNative("track-list/" .. audTrackNum .. "/id")
            local audTrackTitle = propNative("track-list/" .. audTrackNum .. "/title")
            local audTrackLang = propNative("track-list/" .. audTrackNum .. "/lang")

            if (audTrackTitle) then
                audTrackTitle = audTrackTitle .. ((audTrackLang ~= nil) and " (" .. audTrackLang .. ")" or "")
            elseif (audTrackLang) then
                audTrackTitle = audTrackLang
            else
                audTrackTitle = "Audio Track " .. i
            end

            local audTrackCommand = "set aid " .. audTrackID
            if (i == 1) then
                table.insert(
                    audTrackMenuVal,
                    {RADIO, "Disabled", "", "set aid 0", function()
                            return noneCheck("aid")
                        end, false}
                )
                table.insert(audTrackMenuVal, {SEP})
            end
            table.insert(
                audTrackMenuVal,
                {RADIO, audTrackTitle, "", audTrackCommand, function()
                        return checkTrack(audTrackNum)
                    end, false}
            )
        end
    end

    return audTrackMenuVal
end

-- Subtitle > Track menu functions

local function enableSubTrack()
    local subTrackEnable, subTracks = false, trackCount("sub")
    if (#subTracks < 1) then
        subTrackEnable = true
    end
    return subTrackEnable
end

local function checkSubPrimary(trackNum)
    local primaryState, primaryCur = false, propNative("sid")
    local trackID = propNative("track-list/" .. trackNum .. "/id")
    if (primaryCur == trackID) then
        primaryState = true
    end
    return primaryState
end

local function checkSubSecondary(trackNum)
    local secondaryState, secondaryCur = false, propNative("secondary-sid")
    local trackID = propNative("track-list/" .. trackNum .. "/id")
    if (secondaryCur == trackID) then
        secondaryState = true
    end
    return secondaryState
end

local function subTrackMenu()
    local subTrackMenuVal, subTrackCount = {}, trackCount("sub")

    subTrackMenuVal = {}
    if not (#subTrackCount == 0) then
        for i = 1, (#subTrackCount), 1 do
            local subTrackNum = subTrackCount[i]
            local subTrackID = propNative("track-list/" .. subTrackNum .. "/id")
            local subTrackTitle = propNative("track-list/" .. subTrackNum .. "/title")
            local subTrackLang = propNative("track-list/" .. subTrackNum .. "/lang")

            if (subTrackTitle) then
                subTrackTitle = subTrackTitle .. ((subTrackLang ~= nil) and " (" .. subTrackLang .. ")" or "")
            elseif (subTrackLang) then
                subTrackTitle = subTrackLang
            else
                subTrackTitle = "Subtitle Track " .. i
            end

            local subTrackCommand = "set sid " .. subTrackID
            if (i == 1) then
                table.insert(
                    subTrackMenuVal,
                    {RADIO, "Disabled", "", "set sid 0", function()
                            return noneCheck("sid")
                        end, false}
                )
                table.insert(subTrackMenuVal, {SEP})
            end
            table.insert(
                subTrackMenuVal,
                {RADIO, subTrackTitle, "", subTrackCommand, function()
                        return checkTrack(subTrackNum)
                    end, function()
                        return checkSubSecondary(subTrackNum)
                    end}
            )
        end
    end

    return subTrackMenuVal
end

local function secondarySubTrackMenu()
    local subTrackMenuVal, subTrackCount = {}, trackCount("sub")

    subTrackMenuVal = {}
    if not (#subTrackCount == 0) then
        for i = 1, (#subTrackCount), 1 do
            local subTrackNum = subTrackCount[i]
            local subTrackID = propNative("track-list/" .. subTrackNum .. "/id")
            local subTrackTitle = propNative("track-list/" .. subTrackNum .. "/title")
            local subTrackLang = propNative("track-list/" .. subTrackNum .. "/lang")

            if (subTrackTitle) then
                subTrackTitle = subTrackTitle .. ((subTrackLang ~= nil) and " (" .. subTrackLang .. ")" or "")
            elseif (subTrackLang) then
                subTrackTitle = subTrackLang
            else
                subTrackTitle = "Subtitle Track " .. i
            end

            local subTrackCommand = "set secondary-sid " .. subTrackID
            if (i == 1) then
                table.insert(
                    subTrackMenuVal,
                    {RADIO, "Disabled", "", "set secondary-sid 0", function()
                            return noneCheck("secondary-sid")
                        end, false}
                )
                table.insert(subTrackMenuVal, {SEP})
            end
            table.insert(
                subTrackMenuVal,
                {RADIO, subTrackTitle, "", subTrackCommand, function()
                        return checkTrack(subTrackNum)
                    end, function()
                        return checkSubPrimary(subTrackNum)
                    end}
            )
        end
    end

    return subTrackMenuVal
end

-- Playlist functions

local function enablePlaylist()
    local playlistEnable, playlist = false, propNative("playlist/count")
    if (playlist < 1) then
        playlistEnable = true
    end
    return playlistEnable
end

local function playlistMenu()
    local playlistCount = propNative("playlist/count")
    local playlistMenuVal = {}

    playlistMenuVal = {
        {
            COMMAND,
            "Playlist",
            "l",
            "script-message playlistmanager show playlist toggle",
            "",
            false
        },
        {SEP},
        {COMMAND, "Append Files", "", "script-message append-files", "", false},
        {COMMAND, "Shuffle", "", "playlist-shuffle", "", false},
        {COMMAND, "Clear", "Shift+L", "playlist-clear", "", false},
        {SEP}
    }
    if not (playlistCount == 0) then
        for playlistNum = 0, (playlistCount - 1), 1 do
            local playlistTitle = propNative("playlist/" .. playlistNum .. "/title")
            if not (playlistTitle) then
                playlistTitle = propNative("playlist/" .. playlistNum .. "/filename")
            end

            --remove paths if they exist, keeping protocols for stripping
            if string.sub(playlistTitle, 1, 1) == "/" or playlistTitle:match("^%a:[/\\]") then
                _, playlistTitle = utils.split_path(playlistTitle)
            end
            playlistTitle = stripfilename(playlistTitle)

            local playlistCurrent = propNative("playlist/" .. playlistNum .. "/current") or false

            local playlistCommand = "set playlist-pos " .. playlistNum
            if (playlistCurrent) then
                playlistCommand = "ignore"
            end

            table.insert(playlistMenuVal, {RADIO, playlistTitle, "", playlistCommand, playlistCurrent, false})
        end
    end
    return playlistMenuVal
end

--strip a filename based on its extension or protocol according to rules in settings
function stripfilename(pathfile)
    if pathfile == nil then
        return ""
    end
    local ext = pathfile:match("^.+%.(.+)$")
    local protocol = pathfile:match("^(%a%a+)://")
    if not ext then
        ext = ""
    end
    local tmp = pathfile
    return tmp
end

local function nameABLoop()
    local abLoopState = ""
    local abLoopA, abLoopB = propNative("ab-loop-a"), propNative("ab-loop-b")

    if (abLoopA == "no") and (abLoopB == "no") then
        abLoopState = "A-B Loop (Set A)"
    elseif not (abLoopA == "no") and (abLoopB == "no") then
        abLoopState = "A-B Loop (Set B)"
    elseif not (abLoopA == "no") and not (abLoopB == "no") then
        abLoopState = "A-B Loop"
    end

    return abLoopState
end

local function stateABLoop()
    local abLoopState = false
    local abLoopA, abLoopB = propNative("ab-loop-a"), propNative("ab-loop-b")

    if (abLoopA == "no") and (abLoopB == "no") then
        abLoopState = false
    elseif not (abLoopA == "no") and (abLoopB == "no") then
        abLoopState = false
    elseif not (abLoopA == "no") and not (abLoopB == "no") then
        abLoopState = true
    end

    return abLoopState
end

-- Aspect Ratio radio item check
local function stateRatio(ratioVal)
    -- Ratios and Decimal equivalents
    -- Ratios:    "4:3" "16:10"  "16:9" "1.85:1" "2.35:1"
    -- Decimal: "1.333" "1.600" "1.778"  "1.850"  "2.350"
    local ratioState = false
    local ratioCur = round(propNative("video-aspect-override"), 3)

    if (ratioVal == "4:3") and (ratioCur == round(4 / 3, 3)) then
        ratioState = true
    elseif (ratioVal == "16:10") and (ratioVal == round(16 / 10, 3)) then
        ratioState = true
    elseif (ratioVal == "16:9") and (ratioVal == round(16 / 9, 3)) then
        ratioState = true
    elseif (ratioVal == "1.85:1") and (ratioVal == round(1.85 / 1, 3)) then
        ratioState = true
    elseif (ratioVal == "2.39:1") and (ratioVal == round(2.39 / 1, 3)) then
        ratioState = true
    elseif (ratioVal == "2.4:1") and (ratioVal == round(2.4 / 1, 3)) then
        ratioState = true
    end

    return ratioState
end

local function stateFlip(flipVal)
    local vfState, vfVals = false, propNative("vf")
    for i, vf in pairs(vfVals) do
        if (vf["name"] == flipVal) then
            vfState = true
        end
    end
    return vfState
end
 --

--[[ ************ CONFIG: start ************ ]] local menuList = {}

local function refreshMenuList()
    if menuList.vidtrack_menu ~= nil then
        if #menuList.vidtrack_menu ~= trackCount("video") then
            menuList.vidtrack_menu = vidTrackMenu()
        end
    end
    if menuList.audtrack_menu ~= nil then
        if #menuList.audtrack_menu ~= trackCount("audio") then
            menuList.audtrack_menu = audTrackMenu()
        end
    end
    if menuList.subtrack_menu ~= nil then
        if #menuList.subtrack_menu ~= trackCount("sub") then
            menuList.subtrack_menu = subTrackMenu()
        end
    end
    if menuList.playlist_menu ~= nil then
        if #menuList.playlist_menu - 5 ~= propNative("playlist/count") then
            menuList.playlist_menu = playlistMenu()
        end
    end
end

-- Format for object tables
-- {Item Type, Label, Accelerator, Command, Item State, Item Disable, Repost Menu (Optional)}

-- Item Type - The type of item, e.g. CASCADE, COMMAND, CHECK, RADIO, etc
-- Label - The label for the item
-- Accelerator - The text shortcut/accelerator for the item
-- Command - This is the command to run when the item is clicked
-- Item State - The state of the item (selected/unselected). A/B Repeat is a special case.
-- Item Disable - Whether to disable
-- Repost Menu (Optional) - This is only for use with the Tk menu and is optional (only needed
-- if the intent is for the menu item to cause the menu to repost)

-- Item Type, Label and Accelerator should all evaluate to strings as a result of the return
-- from a function or be strings themselves.
-- Command can be a function or string, this will be handled after a click.
-- Item State and Item Disable should normally be boolean but can be a string for A/B Repeat.
-- Repost Menu (Optional) should only be boolean and is only needed if the value is true.

-- This is to be shown when nothing is open yet and is a small subset of the greater menu that
-- will be overwritten when the full menu is created.
menuList = {}

-- DO NOT create the "playing" menu tables until AFTER the file has loaded as we're unable to
-- dynamically create some menus if it tries to build the table before the file is loaded.
-- A prime example is the chapter-list or track-list values, which are unavailable until
-- the file has been loaded.

mp.register_event(
    "file-loaded",
    function()
        menuList = {
            context_menu = {
                {COMMAND, "Open Files", "Ctrl+o", "script-message open-files", "", false},
                {CASCADE, "Open", "add_menu", "", "", false},
                {SEP},
                {CASCADE, "Playback", "playback_menu", "", "", false},
                {CASCADE, "Video", "video_menu", "", "", false},
                {CASCADE, "Audio", "audio_menu", "", "", false},
                {CASCADE, "Subtitle", "subtitle_menu", "", "", false},
                {CASCADE, "Equalizer", "equalizer_menu", "", "", false},
                {CASCADE, "Screenshot", "screenshot_menu", "", "", false},
                {CASCADE, "Audio Resampler", "resampler_menu", "", "", false},
                {CASCADE, "GPU Renderer Options", "renderer_menu", "", "", false},
                {CASCADE, "Miscellaneous", "miscellaneous_menu", "", "", false},
                {SEP},
                {CASCADE, "Performance", "performance_menu", "", "", false},
                {SEP},
                {CHECK, "Fullscreen", "Enter", "cycle fullscreen", function() return propNative("fullscreen") end, false},
                {CHECK, "Always on Top", "Shift+T", "cycle ontop", function() return propNative("ontop") end, false},
                {SEP},
                {CASCADE, "Playlist", "playlist_menu", "", "", function() return enablePlaylist() end},
                {COMMAND, "Stats", "Tab", "script-binding stats/display-stats-toggle", "", false},
                {COMMAND, "MediaInfo", "Shift+Tab", "script-binding mediainfo", "", false},
                {CASCADE, "Tools", "tools_menu", "", "", false},
                {SEP},
                {COMMAND, "About", "Shift+?", "script-binding mpv-update", "", false},
                {SEP},
                {COMMAND, "Dismiss Menu", "", "", "", false},
                {COMMAND, "Quit", "", "quit-watch-later", "", false}
            },

            add_menu = {
                {COMMAND, "Video Tracks", "", "script-message add-videos", "", false},
                {COMMAND, "Audio Tracks", "", "script-message add-audios", "", false},
                {COMMAND, "Subtitles", "", "script-message add-subs", "", false}
            },

            playback_menu = {
                {COMMAND, "Play/Pause", "Space", "cycle pause", "", false},
                {COMMAND, "Stop", "Ctrl+Space", "stop", "", false},
                {SEP},
                {COMMAND, "Previous", "Home/PgUp", "playlist-prev", "", false},
                {COMMAND, "Next", "End/PgDown", "playlist-next", "", false},
                {SEP},
                {CASCADE, "Seek", "seek_menu", "", "", false},
                {SEP},
                {CASCADE, "Speed", "speed_menu", "", "", false},
                {SEP},
                {CASCADE, "Loop", "loop_menu", "", "", false},
                {CASCADE, "A-B Loop", "abloop_menu", "", "", false},
                {SEP},
                {CASCADE, "Chapter", "chapter_menu", "", "", function() return enableChapter() end}
            },

            seek_menu = {
                {COMMAND, "Beginning", "b", "seek 0 absolute", "", false},
                {SEP},
                {COMMAND, "Back", "n", "revert-seek", "", false},
                {SEP},
                {COMMAND, "+1 Sec (Precise)", "Ctrl+f", "seek 1 exact", "", false},
                {COMMAND, "-1 Sec (Precise)", "Ctrl+d", "seek -1 exact", "", false},
                {COMMAND, "+5 Sec", "Right", "seek 5", "", false},
                {COMMAND, "-5 Sec", "Left", "seek -5", "", false},
                {COMMAND, "+5 Sec (Precise)", "Shift+Right", "seek 5 exact", "", false},
                {COMMAND, "-5 Sec (Precise)", "Shift+Left", "seek -5 exact", "", false},
                {COMMAND, "+30 Sec", "Ctrl+Right", "seek 30", "", false},
                {COMMAND, "-30 Sec", "Ctrl+Left", "seek -30", "", false},
                {SEP},
                {COMMAND, "Previous Frame", "d", "script-binding Frame_Back_Step", "", false},
                {COMMAND, "Next Frame", "f", "script-binding Frame_Step", "", false},
                {SEP},
                {COMMAND, "Previous Subtitle", "", "sub-seek -1", "", false},
                {COMMAND, "Current Subtitle", "", "sub-seek 0", "", false},
                {COMMAND, "Next Subtitle", "", "sub-seek 1", "", false},
                {SEP},
                {CHECK, "Precise Seek", "", [[cycle-values hr-seek "absolute" "yes"]], function() return propNative("hr-seek") == "yes" end, false}
            },

            speed_menu = {
                {COMMAND, "Reset", "", [[set speed 1 ; show-text "Speed: ${speed}"]], "", false},
                {SEP},
                {COMMAND, "+10%", "c", "add speed 0.1", "", false},
                {COMMAND, "-10%", "x", "add speed -0.1", "", false}
            },

            loop_menu = {
                {CHECK, "Loop Playlist", "", [[cycle-values loop-playlist "inf" "no"]], function() return propNative("loop-playlist") == "inf" end, false},
                {CHECK, "Loop Current File", "", [[cycle-values loop-file "inf" "no"]], function() return propNative("loop-file") end, false}
            },

            abloop_menu = {
                {CHECK, function() return nameABLoop() end, "", "ab-loop", function() return stateABLoop() end, false}
            },

            -- Use functions returning tables, since we don"t need these menus if there
            -- aren"t any editions or any chapters to seek through.
            edition_menu = editionMenu(),

            chapter_menu = chapterMenu(),

            video_menu = {
                {CASCADE, "Track", "vidtrack_menu", "", "", function() return enableVidTrack() end},
                {SEP},
                {CASCADE, "Hardware Decoding", "hwdec_menu", "", "", false},
                {SEP},
                {CASCADE, "Aspect Ratio", "aspect_menu", "", "", false},
                {CASCADE, "Pan", "pan_menu", "", "", false},
                {CASCADE, "Rotate", "rotate_menu", "", "", false},
                {CASCADE, "Zoom", "zoom_menu", "", "", false},
                {CASCADE, "Align", "align_menu", "", "", false},
                {CASCADE, "Margin", "margin_menu", "", "", false},
                {SEP},
                {CHECK, "Deinterlace", "", "cycle deinterlace", function() return propNative("deinterlace") end, false},
                {CASCADE, "Output Levels", "levels_menu", "", "", false},
                {SEP},
                {CASCADE, "Filters", "filters_menu", "", "", false}
            },
            -- Use function to return list of Video Tracks
            vidtrack_menu = vidTrackMenu(),

            hwdec_menu = {
                {COMMAND, "Auto", "", [[set hwdec "auto"]], "", false},
                {COMMAND, "Auto (Copy)", "", [[set hwdec "auto-copy"]], "", false},
                {SEP},
                {COMMAND, "Auto (Safe)", "", [[set hwdec "auto-safe"]], "", false},
                {COMMAND, "Auto (Copy) (Safe)", "", [[set hwdec "auto-copy-safe"]], "", false},
                {SEP},
                {RADIO, "No", "", [[set hwdec "no"]], function() return propNative("hwdec-current") == "no" end, false},
                {RADIO, "DirectX VA 2", "", [[set hwdec "dxva2"]], function() return propNative("hwdec-current") == "dxva2" end, false},
                {RADIO, "DirectX VA 2 (Copy)", "", [[set hwdec "dxva2-copy"]], function() return propNative("hwdec-current") == "dxva2-copy" end, false},
                {RADIO, "Direct3D 11 VA", "", [[set hwdec "d3d11va"]], function() return propNative("hwdec-current") == "d3d11va" end, false},
                {RADIO, "Direct3D 11 VA (Copy)", "", [[set hwdec "d3d11va-copy"]], function() return propNative("hwdec-current") == "d3d11va-copy" end, false},
                {RADIO, "Nvidia NVENC", "", [[set hwdec "nvdec"]], function() return propNative("hwdec-current") == "nvdec" end, false},
                {RADIO, "Nvidia NVENC (Copy)", "", [[set hwdec "nvdec-copy"]], function() return propNative("hwdec-current") == "nvdec-copy" end, false},
                {RADIO, "CUDA", "", [[set hwdec "cuda"]], function() return propNative("hwdec-current") == "cuda" end, false},
                {RADIO, "CUDA (Copy)", "", [[set hwdec "cuda-copy"]], function() return propNative("hwdec-current") == "cuda-copy" end, false}
            },

            aspect_menu = {
                {RADIO, "Auto", "", [[set video-aspect-override "-1"]], function() return propNative("video-aspect-override") == -1 end, false},
                {SEP},
                {RADIO, "4:3 / TV", "", [[set video-aspect-override "4:3"]], function() return stateRatio("4:3") end, false},
                {RADIO, "16:10", "", [[set video-aspect-override "16:10"]], function() return stateRatio("16:10") end, false},
                {RADIO, "16:9 / HDTV", "", [[set video-aspect-override "16:9"]], function() return stateRatio("16:9") end, false},
                {RADIO, "1.85:1 / Widescreen", "", [[set video-aspect-override "1.85:1"]], function() return stateRatio("1.85:1") end, false},
                {RADIO, "2.39:1 / CinemaScope", "", [[set video-aspect-override "2.4:1"]], function() return stateRatio("2.39:1") end, false},
                {RADIO, "2.4:1", "", [[set video-aspect-override "2.4:1"]], function() return stateRatio("2.4:1") end, false}
            },

            pan_menu = {
                {COMMAND, "Reset", "", "set video-pan-x 0 ; set video-pan-y 0", "", false},
                {COMMAND, "Reset X", "", "set video-pan-x 0", "", false},
                {COMMAND, "Reset Y", "", "set video-pan-y 0", "", false},
                {SEP},
                {COMMAND, "+10% X", "", "add video-pan-x 0.1", "", false},
                {COMMAND, "-10% X", "", "add video-pan-x -0.1", "", false},
                {COMMAND, "+10% Y", "", "add video-pan-y 0.1", "", false},
                {COMMAND, "-10% Y", "", "add video-pan-y -0.1", "", false}
            },

            rotate_menu = {
                {COMMAND, "+90°", "r", "script-message Cycle_Video_Rotate 90", "", false},
                {COMMAND, "-90°", "Shift+R", "script-message Cycle_Video_Rotate -90", "", false},
                {SEP},
                {RADIO, "0°", "", [[set video-rotate "0"]], function() return propNative("video-rotate") == 0 end, false},
                {RADIO, "90°", "", [[set video-rotate "90"]], function() return propNative("video-rotate") == 90 end, false},
                {RADIO, "180°", "", [[set video-rotate "180"]], function() return propNative("video-rotate") == 180 end, false},
                {RADIO, "270°", "", [[set video-rotate "270"]], function() return propNative("video-rotate") == 270 end, false}
            },

            zoom_menu = {
                {COMMAND, "Reset", "", "set panscan 0 ", "", false},
                {SEP},
                {COMMAND, "+10%", "", "add panscan 0.1", "", false},
                {COMMAND, "-10%", "", "add panscan -0.1", "", false}
            },

            align_menu = {
                {COMMAND, "Reset", "", "set video-align-x 0 ; set video-align-y 0", "", false},
                {COMMAND, "Reset X", "", "set video-align-x 0", "", false},
                {COMMAND, "Reset Y", "", "set video-align-y 0", "", false},
                {SEP},
                {COMMAND, "+10% X", "", "add video-align-x 0.1", "", false},
                {COMMAND, "-10% X", "", "add video-align-x -0.1", "", false},
                {COMMAND, "+10% Y", "", "add video-align-y 0.1", "", false},
                {COMMAND, "-10% Y", "", "add video-align-y -0.1", "", false}
            },

            margin_menu = {
                {COMMAND, "Reset", "", "set video-margin-ratio-left 0 ; set video-margin-ratio-right 0 ; set video-margin-ratio-top 0 ; set video-margin-ratio-bottom 0", "", false},
                {COMMAND, "Reset Left", "", "set video-margin-ratio-left 0", "", false},
                {COMMAND, "Reset Right", "", "set video-margin-ratio-right 0", "", false},
                {COMMAND, "Reset Top", "", "set video-margin-ratio-top 0", "", false},
                {COMMAND, "Reset Bottom", "", "set video-margin-ratio-bottom 0", "", false},
                {SEP},
                {COMMAND, "+10% Left", "", "add video-margin-ratio-left 0.1", "", false},
                {COMMAND, "-10% Left", "", "add video-margin-ratio-left -0.1", "", false},
                {COMMAND, "+10% Right", "", "add video-margin-ratio-right 0.1", "", false},
                {COMMAND, "-10% Right", "", "add video-margin-ratio-right -0.1", "", false},
                {COMMAND, "+10% Top", "", "add video-margin-ratio-top 0.1", "", false},
                {COMMAND, "-10% Top", "", "add video-margin-ratio-top -0.1", "", false},
                {COMMAND, "+10% Bottom", "", "add video-margin-ratio-bottom 0.1", "", false},
                {COMMAND, "-10% Bottom", "", "add video-margin-ratio-bottom -0.1", "", false}
            },

            levels_menu = {
                {RADIO, "Auto", "", [[set video-output-levels "auto"]], function() return propNative("video-output-levels") == "auto" end, false},
                {SEP},
                {RADIO, "Full", "", [[set video-output-levels "full"]], function() return propNative("video-output-levels") == "full" end, false},
                {RADIO, "Limited", "", [[set video-output-levels "limited"]], function() return propNative("video-output-levels") == "limited" end, false}
            },

            filters_menu = {
                {COMMAND, "Clear Filters", "", [[vf clr ""]], "", false},
                {SEP},
                {COMMAND, "Flip", "", "set hwdec no ; vf toggle lavfi=vflip", "", false},
                {COMMAND, "Mirror", "", "set hwdec no ; vf toggle lavfi=hflip", "", false},
                {COMMAND, "Crop", "", "set hwdec no ; script-message-to crop start-crop", "", false},
                {COMMAND, "Auto Crop", "", "set hwdec no ; script-binding auto_crop", "", false}
            },

            audio_menu = {
                {CASCADE, "Track", "audtrack_menu", "", "", function() return enableAudTrack() end},
                {SEP},
                {CASCADE, "Volume", "volume_menu", "", "", false},
                {CHECK, "Mute", "m", [[cycle-values mute "yes" "no"]], function() return propNative("mute") end, false},
                {SEP},
                {CHECK, "Pitch Correction", "", "cycle audio-pitch-correction", function() return propNative("audio-pitch-correction") end, false},
                {CHECK, "Exclusive", "", "cycle audio-exclusive", function() return propNative("audio-exclusive") end, false},
                {SEP},
                {CASCADE, "Delay", "auddelay_menu", "", "", false},
                {SEP},
                {CASCADE, "Channels", "channels_menu", "", "", false}
            },

            -- Use function to return list of Audio Tracks
            audtrack_menu = audTrackMenu(),

            volume_menu = {
                {COMMAND, "Reset", "", "set volume 100", "", false},
                {SEP},
                {COMMAND, "+5%", "Up", "add volume 5", "", false},
                {COMMAND, "-5%", "Down", "add volume -5", "", false}
            },

            auddelay_menu = {
                {COMMAND, "Reset", "", "set audio-delay 0", "", false},
                {SEP},
                {COMMAND, "+100 ms", "Shift+>", "add audio-delay 0.1", "", false},
                {COMMAND, "-100 ms", "Shift+<", "add audio-delay -0.1", "", false}
            },

            channels_menu = {
                {RADIO, "Auto", "", [[set audio-channels "auto"]], function() return propNative("audio-channels") == "auto" end, false},
                {RADIO, "Auto (Safe)", "", [[set audio-channels "auto-safe"]], function() return propNative("audio-channels") == "auto-safe" end, false},
                {SEP},
                {RADIO, "Mono", "", [[set audio-channels "mono"]], function() return propNative("audio-channels") == "mono" end, false},
                {RADIO, "Stereo", "", [[set audio-channels "stereo"]], function() return propNative("audio-channels") == "stereo" end, false},
                {RADIO, "5.1", "", [[set audio-channels "5.1"]], function() return propNative("audio-channels") == "5.1" end, false},
                {RADIO, "7.1", "", [[set audio-channels "7.1"]], function() return propNative("audio-channels") == "7.1" end, false}
            },

            subtitle_menu = {
                {CASCADE, "Track", "subtrack_menu", "", "", function() return enableSubTrack() end},
                {SEP},
                {CASCADE, "Secondary Subtitle", "secondarysub_menu", "", "", function() return enableSubTrack() end},
                {SEP},
                {CASCADE, "Delay", "subdelay_menu", "", "", false},
                {SEP},
                {CASCADE, "Scale", "subscale_menu", "", "", false},
                {CASCADE, "Position", "subpos_menu", "", "", false},
                {CHECK, "Place Subtitles in Black Borders", "", "cycle sub-ass-force-margins ; cycle sub-use-margins", function() return propNative("sub-ass-force-margins") end, false},
                {CHECK, "Override Image Subtitle Resolution", "", "cycle image-subs-video-resolution", function() return propNative("image-subs-video-resolution") end, false}
            },

            -- Use function to return list of Subtitle Tracks
            subtrack_menu = subTrackMenu(),

            secondarysub_menu = secondarySubTrackMenu(),

            subdelay_menu = {
                {COMMAND, "Reset", "", "set sub-delay 0", "", false},
                {SEP},
                {COMMAND, "Align to Next", "", "sub-step 1", "", false},
                {COMMAND, "Align to Previous", "", "sub-step -1", "", false},
                {SEP},
                {COMMAND, "+100 ms", ".", "add sub-delay 0.1", "", false},
                {COMMAND, "-100 ms", ",", "add sub-delay -0.1", "", false}
            },

            subscale_menu = {
                {COMMAND, "Reset", "", "set sub-scale 1", "", false},
                {SEP},
                {COMMAND, "+5%", "Alt+.", "add sub-scale 0.05", "", false},
                {COMMAND, "-5%", "Alt+,", "add sub-scale -0.05", "", false}
            },

            subpos_menu = {
                {COMMAND, "Reset", "", "set sub-pos 100", "", false},
                {SEP},
                {COMMAND, "+1%", "Ctrl+,", "add sub-pos 1", "", false},
                {COMMAND, "-1%", "Ctrl+.", "add sub-pos -1", "", false}
            },

            equalizer_menu = {
                {COMMAND, "Reset", "", "set brightness 0 ; set contrast 0 ; set saturation 0 ; set gamma 0 ; set hue 0", "", false},
                {SEP},
                {CASCADE, "Brightness", "brightness_menu", "", "", false},
                {CASCADE, "Contrast", "contrast_menu", "", "", false},
                {CASCADE, "Saturation", "saturation_menu", "", "", false},
                {CASCADE, "Gamma", "gamma_menu", "", "", false},
                {CASCADE, "Hue", "hue_menu", "", "", false}
            },

            brightness_menu = {
                {COMMAND, "Reset", "", "set brightness 0", "", false},
                {SEP},
                {COMMAND, "+5%", "Ctrl+1", "add brightness 5", "", false},
                {COMMAND, "-5%", "Ctrl+Shift+!", "add brightness -5", "", false}
            },

            contrast_menu = {
                {COMMAND, "Reset", "", "set contrast 0", "", false},
                {SEP},
                {COMMAND, "+5%", "Ctrl+2", "add contrast 5", "", false},
                {COMMAND, "-5%", "Ctrl+Shift+@", "add contrast -5", "", false}
            },

            saturation_menu = {
                {COMMAND, "Reset", "", "set saturation 0", "", false},
                {SEP},
                {COMMAND, "+5%", "Ctrl+3", "add saturation 5", "", false},
                {COMMAND, "-5%", "Ctrl+Shift+#", "add saturation -5", "", false}
            },

            gamma_menu = {
                {COMMAND, "Reset", "", "set gamma 0", "", false},
                {SEP},
                {COMMAND, "+5%", "Ctrl+4", "add gamma 5", "", false},
                {COMMAND, "-5%", "Ctrl+Shift+$", "add gamma -5", "", false}
            },

            hue_menu = {
                {COMMAND, "Reset", "", "set hue 0", "", false},
                {SEP},
                {COMMAND, "+5%", "Ctrl+5", "add hue 5", "", false},
                {COMMAND, "-5%", "Ctrl+Shift+%", "add hue -5", "", false}
            },

            screenshot_menu = {
                {COMMAND, "Screenshot", "Ctrl+c", "async screenshot", "", false},
                {COMMAND, "Screenshot (Video Only)", "Ctrl+Shift+C", "async screenshot video", "", false}
            },

            resampler_menu = {
                {CHECK, "Audio Normalize Downmix", "", "cycle audio-normalize-downmix", function() return propNative("audio-normalize-downmix") end, false}
            },

            renderer_menu = {
                {CASCADE, "Scale", "scale_menu", "", "", false},
                {CASCADE, "Chroma Scale", "cscale_menu", "", "", false},
                {CASCADE, "Downscale", "dscale_menu", "", "", false},
                {CASCADE, "Temporal Scale", "tscale_menu", "", "", false},
                {CHECK, "Correct Downscaling", "", "cycle correct-downscaling", function() return propNative("correct-downscaling") end, false},
                {CHECK, "Linear Downscaling", "", "cycle linear-downscaling", function() return propNative("linear-downscaling") end, false},
                {CHECK, "Sigmoid Upscaling", "", "cycle sigmoid-upscaling", function() return propNative("sigmoid-upscaling") end, false},
                {CHECK, "Interpolation", "Shift+I", "cycle interpolation", function() return propNative("interpolation") end, false},
                {CASCADE, "Dither Depth", "dither_menu", "", "", false},
                {CASCADE, "GLSL Shaders", "shaders_menu", "", "", true},
                {CHECK, "Deband", "", "cycle deband", function() return propNative("deband") end, false},
                {CASCADE, "FBO Format", "fbo_menu", "", "", false},
                {SEP},
                {CASCADE, "Display", "display_menu", "", "", false},
                {SEP},
                {CASCADE, "HDR", "hdr_menu", "", "", false}
            },

            scale_menu = {
                {RADIO, "Bilinear", "", [[set scale "bilinear"]], function()
                        return propNative("scale") == "bilinear"
                    end, false},
                {RADIO, "Spline36", "", [[set scale "spline36"]], function()
                        return propNative("scale") == "spline36"
                    end, false},
                {RADIO, "Lanczos", "", [[set scale "lanczos"]], function()
                        return propNative("scale") == "lanczos"
                    end, false},
                {RADIO, "EWA Lanczos", "", [[set scale "ewa_lanczos"]], function()
                        return propNative("scale") == "ewa_lanczos"
                    end, false},
                {RADIO, "EWA Lanczos Sharp", "", [[set scale "ewa_lanczossharp"]], function()
                        return propNative("scale") == "ewa_lanczossharp"
                    end, false},
                {RADIO, "EWA Lanczos Soft", "", [[set scale "ewa_lanczossoft"]], function()
                        return propNative("scale") == "ewa_lanczossoft"
                    end, false},
                {RADIO, "Mitchell", "", [[set scale "mitchell"]], function()
                        return propNative("scale") == "mitchell"
                    end, false},
                {RADIO, "Oversample", "", [[set scale "oversample"]], function()
                        return propNative("scale") == "oversample"
                    end, false}
            },

            cscale_menu = {
                {RADIO, "Bilinear", "", [[set cscale "bilinear"]], function()
                        return propNative("cscale") == "bilinear"
                    end, false},
                {RADIO, "Spline36", "", [[set cscale "spline36"]], function()
                        return propNative("cscale") == "spline36"
                    end, false},
                {RADIO, "Lanczos", "", [[set cscale "lanczos"]], function()
                        return propNative("cscale") == "lanczos"
                    end, false},
                {RADIO, "EWA Lanczos", "", [[set cscale "ewa_lanczos"]], function()
                        return propNative("cscale") == "ewa_lanczos"
                    end, false},
                {RADIO, "EWA Lanczos Sharp", "", [[set cscale "ewa_lanczossharp"]], function()
                        return propNative("cscale") == "ewa_lanczossharp"
                    end, false},
                {RADIO, "EWA Lanczos Soft", "", [[set cscale "ewa_lanczossoft"]], function()
                        return propNative("cscale") == "ewa_lanczossoft"
                    end, false},
                {RADIO, "Mitchell", "", [[set cscale "mitchell"]], function()
                        return propNative("cscale") == "mitchell"
                    end, false},
                {RADIO, "Oversample", "", [[set cscale "oversample"]], function()
                        return propNative("cscale") == "oversample"
                    end, false}
            },

            dscale_menu = {
                {RADIO, "Bilinear", "", [[set dscale "bilinear"]], function()
                        return propNative("dscale") == "bilinear"
                    end, false},
                {RADIO, "Spline36", "", [[set dscale "spline36"]], function()
                        return propNative("dscale") == "spline36"
                    end, false},
                {RADIO, "Lanczos", "", [[set dscale "lanczos"]], function()
                        return propNative("dscale") == "lanczos"
                    end, false},
                {RADIO, "EWA Lanczos", "", [[set dscale "ewa_lanczos"]], function()
                        return propNative("dscale") == "ewa_lanczos"
                    end, false},
                {RADIO, "EWA Lanczos Sharp", "", [[set dscale "ewa_lanczossharp"]], function()
                        return propNative("dscale") == "ewa_lanczossharp"
                    end, false},
                {RADIO, "EWA Lanczos Soft", "", [[set dscale "ewa_lanczossoft"]], function()
                        return propNative("dscale") == "ewa_lanczossoft"
                    end, false},
                {RADIO, "Mitchell", "", [[set dscale "mitchell"]], function()
                        return propNative("dscale") == "mitchell"
                    end, false},
                {RADIO, "Oversample", "", [[set dscale "oversample"]], function()
                        return propNative("dscale") == "oversample"
                    end, false}
            },

            tscale_menu = {
                {RADIO, "Oversample", "", [[set tscale "oversample"]], function()
                        return propNative("tscale") == "oversample"
                    end, false},
                {RADIO, "Linear", "", [[set tscale "linear"]], function()
                        return propNative("tscale") == "linear"
                    end, false},
                {RADIO, "Catmull-Rom", "", [[set tscale "catmull_rom"]], function()
                        return propNative("tscale") == "catmull_rom"
                    end, false},
                {RADIO, "Mitchell", "", [[set tscale "mitchell"]], function()
                        return propNative("tscale") == "mitchell"
                    end, false},
                {RADIO, "Bicubic", "", [[set tscale "bicubic"]], function()
                        return propNative("tscale") == "bicubic"
                    end, false}
            },

            dither_menu = {
                {RADIO, "No", "", [[set dither-depth "oversample"]], function()
                        return propNative("dither-depth") == "no"
                    end, false},
                {RADIO, "Auto", "", [[set dither-depth "auto"]], function()
                        return propNative("dither-depth") == "auto"
                    end, false},
                {SEP},
                {RADIO, "8-bit", "", [[set dither-depth "8"]], function()
                        return propNative("dither-depth") == "8"
                    end, false},
                {RADIO, "16-bit", "", [[set dither-depth "16"]], function()
                        return propNative("dither-depth") == "16"
                    end, false}
            },

            shaders_menu = {},

            fbo_menu = {
                {RADIO, "Auto", "", [[set fbo-format "auto"]], function()
                        return propNative("fbo-format") == "auto"
                    end, false},
                {SEP},
                {RADIO, "RGB8", "", [[set fbo-format "rgb8"]], function()
                        return propNative("fbo-format") == "rgb8"
                    end, false},
                {RADIO, "RGB10_A2", "", [[set fbo-format "rgb10_a2"]], function()
                        return propNative("fbo-format") == "rgb10_a2"
                    end, false},
                {RADIO, "RGBA16", "", [[set fbo-format "rgba16"]], function()
                        return propNative("fbo-format") == "rgba16"
                    end, false},
                {RADIO, "RGBA16F", "", [[set fbo-format "rgba16f"]], function()
                        return propNative("fbo-format") == "rgba16f"
                    end, false},
                {RADIO, "RGBA16HF", "", [[set fbo-format "rgba16hf"]], function()
                        return propNative("fbo-format") == "rgba16hf"
                    end, false},
                {RADIO, "RGBA32F", "", [[set fbo-format "rgba32f"]], function()
                        return propNative("fbo-format") == "rgba32f"
                    end, false}
            },

            display_menu = {
                {CASCADE, "Primary", "primary_menu", "", "", false},
                {CASCADE, "Gamma", "trc_menu", "", "", false},
                {CHECK, "Load ICC Profile", "", "cycle icc-profile-auto", function() return propNative("icc-profile-auto") end, false}
            },

            primary_menu = {
                {RADIO, "Auto", "", [[set target-prim "auto"]], function()
                        return propNative("target-prim") == "auto"
                    end, false},
                {SEP},
                {RADIO, "ITU-R BT.470 M", "", [[set target-prim "bt.470m"]], function()
                        return propNative("target-prim") == "bt.470m"
                    end, false},
                {RADIO, "ITU-R BT.601 (525)", "", [[set target-prim "bt.601-525"]], function()
                        return propNative("target-prim") == "bt.601-525"
                    end, false},
                {RADIO, "ITU-R BT.601 (625)", "", [[set target-prim "bt.601-625"]], function()
                        return propNative("target-prim") == "bt.601-625"
                    end, false},
                {RADIO, "ITU-R BT.709", "", [[set target-prim "bt.709"]], function()
                        return propNative("target-prim") == "bt.709"
                    end, false},
                {RADIO, "ITU-R BT.2020", "", [[set target-prim "bt.2020"]], function()
                        return propNative("target-prim") == "bt.2020"
                    end, false},
                {RADIO, "Apple RGB", "", [[set target-prim "apple"]], function()
                        return propNative("target-prim") == "apple"
                    end, false},
                {RADIO, "Adobe RGB (1998)", "", [[set target-prim "adobe"]], function()
                        return propNative("target-prim") == "adobe"
                    end, false},
                {RADIO, "ProPhoto RGB", "", [[set target-prim "prophoto"]], function()
                        return propNative("target-prim") == "prophoto"
                    end, false},
                {RADIO, "CIE 1931 RGB", "", [[set target-prim "cie1931"]], function()
                        return propNative("target-prim") == "cie1931"
                    end, false},
                {RADIO, "DCI-P3", "", [[set target-prim "dci-p3"]], function()
                        return propNative("target-prim") == "dci-p3"
                    end, false},
                {RADIO, "Panasonic V-Gamut", "", [[set target-prim "v-gamut"]], function()
                        return propNative("target-prim") == "v-gamut"
                    end, false},
                {RADIO, "Sony S-Gamut", "", [[set target-prim "s-gamut"]], function()
                        return propNative("target-prim") == "s-gamut"
                    end, false}
            },

            trc_menu = {
                {RADIO, "Auto", "", [[set target-trc "auto"]], function()
                        return propNative("target-trc") == "auto"
                    end, false},
                {SEP},
                {RADIO, "ITU-R BT.1886", "", [[set target-trc "bt.1886"]], function()
                        return propNative("target-trc") == "bt.1886"
                    end, false},
                {RADIO, "sRGB", "", [[set target-trc "srgb"]], function()
                        return propNative("target-trc") == "srgb"
                    end, false},
                {RADIO, "Linear", "", [[set target-trc "linear"]], function()
                        return propNative("target-trc") == "linear"
                    end, false},
                {RADIO, "1.8 / Apple RGB", "", [[set target-trc "gamma1.8"]], function()
                        return propNative("target-trc") == "gamma1.8"
                    end, false},
                {RADIO, "2.0", "", [[set target-trc "gamma2.0"]], function()
                        return propNative("target-trc") == "gamma2.0"
                    end, false},
                {RADIO, "2.2", "", [[set target-trc "gamma2.2"]], function()
                        return propNative("target-trc") == "gamma2.2"
                    end, false},
                {RADIO, "2.4", "", [[set target-trc "gamma2.4"]], function()
                        return propNative("target-trc") == "gamma2.4"
                    end, false},
                {RADIO, "2.6", "", [[set target-trc "gamma2.6"]], function()
                        return propNative("target-trc") == "gamma2.6"
                    end, false},
                {RADIO, "2.8", "", [[set target-trc "gamma2.8"]], function()
                        return propNative("target-trc") == "gamma2.8"
                    end, false},
                {RADIO, "ProPhoto RGB", "", [[set target-trc "prophoto"]], function()
                        return propNative("target-trc") == "prophoto"
                    end, false},
                {RADIO, "ITU-R BT.2100 PQ", "", [[set target-trc "pq"]], function()
                        return propNative("target-trc") == "pq"
                    end, false},
                {RADIO, "ITU-R BT.2100 HLG", "", [[set target-trc "hlg"]], function()
                        return propNative("target-trc") == "hlg"
                    end, false},
                {RADIO, "Panasonic V-Log", "", [[set target-trc "v-log"]], function()
                        return propNative("target-trc") == "v-log"
                    end, false},
                {RADIO, "Sony S-Log1", "", [[set target-trc "s-log1"]], function()
                        return propNative("target-trc") == "s-log1"
                    end, false},
                {RADIO, "Sony S-Log2", "", [[set target-trc "s-log2"]], function()
                        return propNative("target-trc") == "s-log2"
                    end, false}
            },

            hdr_menu = {
                {CASCADE, "Target Peak", "peak_menu", "", "", false},
                {CASCADE, "Tone Mapping", "tonemap_menu", "", "", false},
                {CASCADE, "Tone Mapping Max Boost", "boost_menu", "", "", false},
                {CASCADE, "Tone Mapping Desaturate", "desaturate_menu", "", "", false},
                {CASCADE, "Tone Mapping Desaturate Exponent", "exponent_menu", "", "", false}
            },

            peak_menu = {
                {RADIO, "Auto", "", [[set target-peak "auto"]], function()
                        return propNative("target-peak") == "auto"
                    end, false},
                {SEP},
                {RADIO, "100 nit / SDR", "", [[set target-peak "100"]], function()
                        return propNative("target-peak") == "100"
                    end, false},
                {RADIO, "300 nit", "", [[set target-peak "300"]], function()
                        return propNative("target-peak") == "300"
                    end, false},
                {RADIO, "400 nit / DisplayHDR 400", "", [[set target-peak "400"]], function()
                        return propNative("target-peak") == "400"
                    end, false},
                {RADIO, "500 nit", "", [[set target-peak "500"]], function()
                        return propNative("target-peak") == "500"
                    end, false},
                {RADIO, "600 nit / DisplayHDR 600", "", [[set target-peak "600"]], function()
                        return propNative("target-peak") == "600"
                    end, false},
                {RADIO, "800 nit", "", [[set target-peak "800"]], function()
                        return propNative("target-peak") == "800"
                    end, false},
                {RADIO, "1000 nit / DisplayHDR 1000", "", [[set target-peak "1000"]], function()
                        return propNative("target-peak") == "1000"
                    end, false},
                {SEP},
                {COMMAND, "+50 nit", "", "add target-peak 50", "", false},
                {COMMAND, "-50 nit", "", "add target-peak -50", "", false}
            },

            tonemap_menu = {
                {RADIO, "Clip", "", [[set tone-mapping "clip"]], function()
                        return propNative("tone-mapping") == "clip"
                    end, false},
                {RADIO, "Linear", "", [[set tone-mapping "linear"]], function()
                        return propNative("tone-mapping") == "linear"
                    end, false},
                {RADIO, "Gamma", "", [[set tone-mapping "gamma"]], function()
                        return propNative("tone-mapping") == "gamma"
                    end, false},
                {RADIO, "Mobius", "", [[set tone-mapping "mobius"]], function()
                        return propNative("tone-mapping") == "mobius"
                    end, false},
                {RADIO, "Reinhard", "", [[set tone-mapping "reinhard"]], function()
                        return propNative("tone-mapping") == "reinhard"
                    end, false},
                {RADIO, "Hable", "", [[set tone-mapping "hable"]], function()
                        return propNative("tone-mapping") == "hable"
                    end, false}
            },

            boost_menu = {
                {COMMAND, "Reset", "", "set tone-mapping-max-boost 1.0", "", false},
                {SEP},
                {COMMAND, "+0.5", "", "add tone-mapping-max-boost 0.5", "", false},
                {COMMAND, "-0.5", "", "add tone-mapping-max-boost -0.5", "", false}
            },

            desaturate_menu = {
                {COMMAND, "Reset", "", "set tone-mapping-desaturate 0.75", "", false},
                {SEP},
                {COMMAND, "+5%", "", "add tone-mapping-desaturate 0.05", "", false},
                {COMMAND, "-5%", "", "add tone-mapping-desaturate -0.05", "", false}
            },

            exponent_menu = {
                {COMMAND, "Reset", "", "set tone-mapping-desaturate-exponent 1.5", "", false},
                {SEP},
                {COMMAND, "+0.5", "", "add tone-mapping-desaturate-exponent 0.5", "", false},
                {COMMAND, "-0.5", "", "add tone-mapping-desaturate-exponent -0.5", "", false}
            },

            miscellaneous_menu = {
                {CASCADE, "Video Sync", "vidsync_menu", "", "", false}
            },

            vidsync_menu = {
                {RADIO, "Audio", "", [[set video-sync "audio"]], function() return propNative("video-sync") == "audio" end, false},
                {RADIO, "Display Resample", "", [[set video-sync "display-resample"]], function() return propNative("video-sync") == "display-resample" end, false},
                {RADIO, "Display Resample (Drop Video Frames)", "", [[set video-sync "display-resample-vdrop"]], function() return propNative("video-sync") == "display-resample-vdrop" end, false},
                {RADIO, "Display Resample (Desync)", "", [[set video-sync "display-resample-desync"]], function() return propNative("video-sync") == "display-resample-desync" end, false},
                {RADIO, "Display (Drop Video Frames)", "", [[set video-sync "display-vdrop"]], function() return propNative("video-sync") == "display-vdrop" end, false},
                {RADIO, "Display (Drop Audio Data)", "", [[set video-sync "display-adrop"]], function() return propNative("video-sync") == "display-adrop" end, false},
                {RADIO, "Display (Desync)", "", [[set video-sync "display-desync"]], function() return propNative("video-sync") == "display-desync" end, false},
                {RADIO, "Desync", "", [[set video-sync "desync"]], function() return propNative("video-sync") == "desync" end, false}
            },

            performance_menu = {
                {COMMAND, "Hehe's Choice / Low Quality", "", "no-osd set profile hehes-choice", "", false},
                {COMMAND, "Standard Quality", "", "no-osd set profile standard-quality", "", false},
                {COMMAND, "High Quality", "", "no-osd set profile high-quality", "", false},
                {COMMAND, "Jiji's Select", "", "no-osd set profile jijis-select", "", false},
                {COMMAND, "Jiji's Choice", "", "no-osd set profile jijis-choice", "", false},
                {COMMAND, "Jiji's Prime", "", "no-osd set profile jijis-prime", "", false},
                {COMMAND, "Jiji's Prime Plus", "j-i-j-i", "no-osd set profile jijis-prime-plus", "", false},
                {COMMAND, "Jiji's Prime MAX", "Shift+J-i-j-i", "no-osd set profile jijis-prime-max", "", false}
            },

            -- Use function to return list of Playlist
            playlist_menu = playlistMenu(),

            tools_menu = {
                {COMMAND, "Blackout", "`", "script-binding blackout/blackout", "", false},
                {COMMAND, "Generate Thumbnails", "Ctrl+t", "script-binding generate-thumbnails", "", false},
                {COMMAND, "Locate...", "Ctrl+l", "script-message locate-current-file", "", false},
                {COMMAND, "Console", "Shift+~", "script-binding console/enable", "", false}
            }
        }

        -- This check ensures that all tables of data without SEP in them are 6 or 7 items long.
        for key, value in pairs(menuList) do
            for i = 1, #value do
                if (value[i][1] ~= SEP) then
                    if (#value[i] < 6 or #value[i] > 7) then
                        mpdebug("Menu item at index of " .. i .. " is " .. #value[i] .. " items long for: " .. key)
                    end
                end
            end
        end
    end
)
 --

--[[ ************ CONFIG: end ************ ]] local menuEngine = require "menu-engine"

mp.register_script_message(
    "mpv_context_menu_tk",
    function()
        refreshMenuList()
        menuEngine.createMenu(menuList, "context_menu", -1, -1, "tk")
    end
)

mp.register_script_message(
    "mpv_context_menu_gtk",
    function()
        refreshMenuList()
        menuEngine.createMenu(menuList, "context_menu", -1, -1, "gtk")
    end
)
