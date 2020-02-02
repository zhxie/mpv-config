local libass_names = {"libass", "libass-4", "libass-5", "libass-9", "ass"}
local libass_path = nil
local ffi = require "ffi"
ffi.cdef[[
typedef struct ass_renderer ASS_Renderer;
typedef struct render_priv ASS_RenderPriv;
typedef struct parser_priv ASS_ParserPriv;
typedef struct ass_library ASS_Library;
typedef struct ass_style {char *Name; char *FontName; double FontSize; uint32_t PrimaryColour; uint32_t SecondaryColour; uint32_t OutlineColour; uint32_t BackColour; int Bold; int Italic; int Underline; int StrikeOut; double ScaleX; double ScaleY; double Spacing; double Angle; int BorderStyle; double Outline; double Shadow; int Alignment; int MarginL; int MarginR; int MarginV; int Encoding; int treat_fontname_as_pattern; double Blur; int Justify;} ASS_Style;
typedef struct ass_event {long long Start; long long Duration; int ReadOrder; int Layer; int Style; char *Name; int MarginL; int MarginR; int MarginV; char *Effect; char *Text; ASS_RenderPriv *render_priv;} ASS_Event;
typedef enum ASS_YCbCrMatrix {YCBCR_DEFAULT = 0, YCBCR_UNKNOWN, YCBCR_NONE, YCBCR_BT601_TV, YCBCR_BT601_PC, YCBCR_BT709_TV, YCBCR_BT709_PC, YCBCR_SMPTE240M_TV, YCBCR_SMPTE240M_PC, YCBCR_FCC_TV, YCBCR_FCC_PC} ASS_YCbCrMatrix;
typedef struct ass_track {int n_styles; int max_styles; int n_events; int max_events; ASS_Style *styles; ASS_Event *events; char *style_format; char *event_format; enum {TRACK_TYPE_UNKNOWN = 0, TRACK_TYPE_ASS, TRACK_TYPE_SSA} track_type; int PlayResX; int PlayResY; double Timer; int WrapStyle; int ScaledBorderAndShadow; int Kerning; char *Language; ASS_YCbCrMatrix YCbCrMatrix; int default_style; char *name; ASS_Library *library; ASS_ParserPriv *parser_priv;} ASS_Track;
typedef struct ass_image {int w, h; int stride; unsigned char *bitmap; uint32_t color; int dst_x, dst_y; struct ass_image *next; enum {IMAGE_TYPE_CHARACTER, IMAGE_TYPE_OUTLINE, IMAGE_TYPE_SHADOW} type;} ASS_Image;
ASS_Library *ass_library_init(void);
void ass_library_done(ASS_Library *);
ASS_Renderer *ass_renderer_init(ASS_Library *);
ASS_Image *ass_render_frame(ASS_Renderer *, ASS_Track *, long long, int *);
void ass_renderer_done(ASS_Renderer *);
ASS_Track *ass_read_file(ASS_Library *, const char *, const char *);
void ass_free_track(ASS_Track *);
ASS_Track *ass_new_track(ASS_Library *);
void ass_free_track(ASS_Track *);
int ass_alloc_style(ASS_Track *);
int ass_alloc_event(ASS_Track *);
long long ass_step_sub(ASS_Track *, long long, int);
void ass_set_frame_size(ASS_Renderer *, int, int);
void ass_set_fonts(ASS_Renderer *, const char *, const char *, int, const char *, int);
void ass_set_fonts_dir(ASS_Library *, const char *);
void *malloc(size_t);
char *strcpy(char *, const char *);
size_t strlen(const char *s);
]]

utils = require "mp.utils"

local utils = require "mp.utils"
local assdraw = require "mp.assdraw"
local ffmpeg = nil
local scripts_dir = mp.command_native({"expand-path", "~~home/scripts"})

local ON_WINDOWS = (package.config:sub(1,1) ~= '/')

function file_exists(name)
    local f = io.open(name, "rb")
    if f ~= nil then
        local ok, err, code = f:read(1)
        io.close(f)
        return code == nil
    else
        return false
    end
end

function find_executable(name)
    local delim = ON_WINDOWS and ";" or ":"

    local pwd = os.getenv("PWD") or utils.getcwd()
    local path = os.getenv("PATH")

    local env_path = pwd .. delim .. path

    local result, filename
    for path_dir in env_path:gmatch("[^"..delim.."]+") do
        filename = utils.join_path(path_dir, name)
        if file_exists(filename) then
            result = filename
            break
        end
    end

    return result
end

local options = {
    paused_only = false,
    on_hover = true,
    autohide = true,
    libass_path = "",
    fonts_dir = utils.join_path(scripts_dir, "shared/fonts"),
    tmp_ass = utils.join_path(scripts_dir, "shared/subs.ass")
}

mp.options = require "mp.options"
mp.options.read_options(options, "libass_sub_selector")

if options.libass_path == "" then
    for _, libass_name in ipairs(libass_names) do
        libass_name = ON_WINDOWS and (libass_name .. ".dll") or libass_name
        libass_path = find_executable(libass_name)
        if libass_path then break end
    end

    if not libass_path then
        return mp.msg.error("Could not find libass path, tried the following:", table.concat(libass_names, ", "))
    end
else
    libass_path = options.libass_path
end

local ass = ffi.load(libass_path, true)
local tmp_ass = options.tmp_ass
local cache = {file = nil, index = -1, pos = -1, last = 0, w = -1, h = -1, events = {}, bounds = {}, mouse = {pos_x = -1, pos_y = -1, last = 0, autohide = nil}}
local show_all = false

function strdup(src)
    local dst = ffi.C.malloc(ffi.C.strlen(src) + 1)
    return ffi.C.strcpy(dst, src)
end

local library, renderer, track, events, width, height
function init_libass(file, result)
    if not file or file == true then file = options.tmp_ass end
    if result and result.killed_by_us then return end
    ffmpeg = nil
    library = ffi.gc(ass.ass_library_init(), ass.ass_library_done)
    renderer = ffi.gc(ass.ass_renderer_init(library), ass.ass_renderer_done)
    width = mp.get_property_native("width")
    if not width then return end
    height = mp.get_property_native("height")
    ass.ass_set_frame_size(renderer, width, height)
    ass.ass_set_fonts_dir(library, options.fonts_dir)
    ass.ass_set_fonts(renderer, nil, "sans-serif", 1, nil, 1)
    track = ffi.gc(ass.ass_read_file(library, file, nil), ass.ass_free_track)
    events = {}
    for i = 0, track.n_events-1 do
        table.insert(events, track.events[i])
    end
    return events
end

function clear_subs()
    if events ~= nil then
        mp.set_osd_ass(0, 0, "")
        events = nil
        cache.index = nil
    end
end

local last_extracted = nil

function event_track(event, i)
    if cache.events[i] then
        return cache.events[i]
    end
    local ret = ffi.gc(ass.ass_new_track(library), ass.ass_free_track)
    ret.style_format = strdup(track.style_format)
    ret.event_format = strdup(track.event_format)
    ret.track_type = track.track_type
    ret.PlayResX = track.PlayResX
    ret.PlayResY = track.PlayResY
    ret.WrapStyle = track.WrapStyle
    ret.ScaledBorderAndShadow = track.ScaledBorderAndShadow
    ret.Kerning = track.Kerning
    if track.Language ~= nil then
        ret.Language = strdup(track.Language)
    end
    ret.YCbCrMatrix = track.YCbCrMatrix
    if track.name ~= nil then
        ret.name = strdup(track.name)
    end
    local style_id = ass.ass_alloc_style(ret)
    ret.default_style = style_id
    local orig = track.styles[event.Style]
    ffi.copy(ret.styles[style_id], track.styles[event.Style], ffi.sizeof("ASS_Style"))
    ret.styles[style_id].Name = strdup(orig.Name)
    ret.styles[style_id].FontName = strdup(orig.FontName)
    local event_id = ass.ass_alloc_event(ret)
    local render_priv = ret.events[event_id].render_priv
    ffi.copy(ret.events[event_id], event, ffi.sizeof("ASS_Event"))
    ret.events[event_id].Name = strdup(event.Name)
    ret.events[event_id].Layer = event.Layer
    ret.events[event_id].Effect = strdup(event.Effect)
    ret.events[event_id].Text = strdup(event.Text)
    ret.events[event_id].Style = style_id
    ret.events[event_id].render_priv = render_priv
    cache.events[i] = ret
    return ret
end

function bounds(b_track, time, index)
    if cache.bounds[index] then
        return unpack(cache.bounds[index])
    end
    local change = ffi.new("int[1]")
    local image = ass.ass_render_frame(renderer, b_track, time, change)
    local min_x = width
    local min_y = height
    local max_x = 0
    local max_y = 0
    while image ~= nil do
        if image.dst_x < min_x then
            min_x = image.dst_x
        end
        if image.dst_y < min_y then
            min_y = image.dst_y
        end
        if (image.dst_x + image.w) > max_x then
            max_x = image.dst_x + image.w
        end
        if (image.dst_y + image.h) > max_y then
            max_y = image.dst_y + image.h
        end
        image = image.next
    end
    min_x = min_x + cache.offset_x
    min_y = min_y + cache.offset_y
    max_x = max_x + cache.offset_x
    max_y = max_y + cache.offset_y
    cache.bounds[index] = {min_x, min_y, max_x, max_y}
    return min_x, min_y, max_x, max_y
end

function events_at(time)
    local ret = {}
    for i, v in ipairs(events) do
        if v.Start <= time and time < (v.Start + v.Duration) then
            table.insert(ret, {event = v, index = i})
        end
    end
    return ret
end

function copy_subs(text)
    local res = mp.commandv("run", "powershell", "-NoProfile", "-Command", string.format([[& {
      Trap {
        Write-Error -ErrorRecord $_
        Exit 1
      }
      Add-Type -AssemblyName PresentationCore
      [System.Windows.Clipboard]::SetText(@"
%s
"@)
    }]], text))
end

function compare_subs(a, b)
    if a.event.Layer == b.event.Layer then
        local a_min_x, a_min_y, a_max_x, a_max_y = bounds(event_track(a.event, a.index), cache.pos, a.index)
        local b_min_x, b_min_y, b_max_x, b_max_y = bounds(event_track(b.event, b.index), cache.pos, b.index)
        return (a_max_x - a_min_x) * (a_max_y - a_min_y) < (b_max_x - b_min_x) * (b_max_y - b_min_y)
    end
    return a.event.Layer > b.event.Layer
end

function tick(copy)
    if copy == true and events == nil then copy_subs(mp.get_property_native("sub-text")) end
    if events == nil then return end
    if options.paused_only and not mp.get_property_native("core-idle") then return mp.set_osd_ass(width, height, "") end
    local pos = mp.get_property_native("time-pos")
    if not pos then return end
    pos = pos + mp.get_property_native("sub-delay")
    pos = pos * 1000
    local w, h = mp.get_osd_size()
    local scale = math.max(width / w, height / h)
    local border_x = (w - width / scale) / 2
    local border_y = (h - height / scale) / 2
    if pos ~= cache.pos or w ~= cache.w or h ~= cache.h then
        cache.last = -1
        cache.pos = pos
        cache.w = w
        cache.h = h
        cache.bounds = {}
        cache.events = {}
        cache.offset_x = border_x * scale
        cache.offset_y = border_y * scale
        if options.autohide then
            cache.mouse.autohide = mp.get_property_native("cursor-autohide")
        end
    end
    local x, y = mp.get_mouse_pos()
    if x ~= cache.mouse.pos_x or y ~= cache.mouse.pos_y then
        cache.mouse.pos_x = x
        cache.mouse.pos_y = y
        cache.mouse.last = mp.get_time()
    end
    local events = events_at(pos)
    table.sort(events, compare_subs)
    local ass = assdraw.ass_new()
    local show = false
    local pos_x = (x - border_x) * scale + cache.offset_x
    local pos_y = (y - border_y) * scale + cache.offset_y
    local to_copy = {}
    for i, v in ipairs(events) do
        local track_event = event_track(v.event, v.index)
        local min_x, min_y, max_x, max_y = bounds(track_event, pos, v.index)
        if show_all or (options.on_hover and pos_x > min_x and pos_x < max_x and pos_y > min_y and pos_y < max_y) then
            if copy == true then
                local line = ffi.string(v.event.Text):gsub("{\\([^}]*p1.*?\\p0)[^}]*}", ""):gsub("{\\([^}]*p1)[^}]*}.*", ""):gsub("{\\[^}]+}", ""):gsub("\\N", "\n"):gsub("\\n", "\n"):gsub("\\h", " ")
                if line ~= "" then
                    to_copy[#to_copy+1] = line
                end
            end
            if not show_all and options.autohide and type(cache.mouse.autohide) == "number" and (not mp.get_property_native("cursor-autohide-fs-only") or mp.get_property_native("fullscreen")) and mp.get_time() * 1000 - cache.mouse.last * 1000 > cache.mouse.autohide then
                break
            end
            if cache.last == v.index then return end
            cache.last = v.index
            min_x = math.max(min_x, 2)
            min_y = math.max(min_y, 2)
            max_x = math.min(max_x, width - 2)
            max_y = math.min(max_y, height - 2)
            ass:new_event()
            ass:append("{\\3c&H0000ff&}")
            ass:append("{\\bord2}")
            ass:append("{\\1a&HFF&}")
            ass:pos(0, 0)
            ass:draw_start()
            ass:move_to(min_x, min_y)
            ass:line_to(max_x, min_y)
            ass:line_to(max_x, max_y)
            ass:line_to(min_x, max_y)
            ass:draw_stop()
            show = true
            if not show_all then break end
        end
    end
    if copy == true then
        copy_subs(table.concat(to_copy, "\n"))
    end
    mp.set_osd_ass(width, height, ass.text)
    cache.last = 0
end

function init_track()
    local track_list = mp.get_property_native("track-list")
    for i, v in ipairs(track_list) do
        if v.type == "sub" and v.selected and (v.codec == "ass" or v.codec == "ssa") then
            if not v.external then
                if ffmpeg == nil and v["ff-index"] == last_extracted then return init_libass() end
                if ffmpeg ~= nil then
                    mp.abort_async_command(ffmpeg)
                    ffmpeg = nil
                end
                last_extracted = v["ff-index"]
                cache.index = v["ff-index"]
                ffmpeg = mp.command_native_async({"subprocess", {
                    "ffmpeg", "-loglevel", "8",
                    "-i", cache.file,
                    "-map", "0:" .. v["ff-index"],
                    "-y", options.tmp_ass
                }}, init_libass)
            else
                if v["external-filename"] == cache.index then return end
                cache.index = v["external-filename"]
                init_libass(v["external-filename"])
            end
            return
        end
    end
    clear_subs()
end

function file_loaded()
    mp.unregister_event(init_track)
    local path = mp.get_property_native("path")
    if not path then return end
    local working_directory = mp.get_property_native("working-directory")
    local file = utils.join_path(working_directory, path)
    local skip = true
    local track_list = mp.get_property_native("track-list")
    for i, v in ipairs(track_list) do
        if v.type == "sub" and (v.codec == "ass" or v.codec == "ssa") then
            skip = false
            break
        end
    end

    if skip then return clear_subs() end
    if file ~= cache.file then
        cache.file = file
        fonts = utils.readdir(options.fonts_dir, "files")
        if fonts then
            for _, font in ipairs(fonts) do
                os.remove(utils.join_path(options.fonts_dir, font))
            end
        end
        local tracks = mp.command_native{name = "subprocess", capture_stdout = true, playback_only = false, args = {
            "mkvmerge",
            "-J",
            file
        }}
        local json = utils.parse_json(tracks.stdout)
        local args = {"mkvextract", "attachments", file}
        for key, value in pairs(json.attachments) do
            table.insert(args, value.id .. ":" .. options.fonts_dir .. "/" .. value.file_name)
        end
        mp.command_native_async({name = "subprocess", playback_only = false, args = args}, init_track)
        mp.register_event("track-switched", init_track)
    else
        init_track()
        mp.register_event("track-switched", init_track)
    end
end

function toggle_bounds()
    show_all = not show_all
end

mp.register_event("file-loaded", file_loaded)
mp.register_event("tick", tick)

mp.add_key_binding("c", "copy-subs", function() return tick(true) end)
mp.add_key_binding("b", "toggle-bounds", toggle_bounds)
