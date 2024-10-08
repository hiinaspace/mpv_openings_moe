local utils = require 'mp.utils'
local msg = require 'mp.msg'

local api_url = "https://api.animethemes.moe/animetheme"
local video_data = {}

function get_video_details()
    local params = api_url .. "?page%5Bsize%5D=1&filter%5Bhas%5D=anime%2Canimethemeentries&filter%5Bspoiler%5D=false&sort=random&include=group%2Canime.images%2Csong.artists%2Canimethemeentries.videos.audio"
    
    msg.info("Fetching video details from AnimeThemes.moe")
    msg.info("API URL: " .. params)
    
    local res = mp.command_native({
        name = "subprocess",
        args = {"curl", "-s", "-A", "mpv_animethemes_moe/1.0", params},
        capture_stdout = true,
        playback_only = false
    })

    local response = utils.parse_json(res.stdout)

    if response and response.animethemes and #response.animethemes > 0 then
        local theme = response.animethemes[1]
        local anime = theme.anime
        local song = theme.song
        local entry = theme.animethemeentries[1]
        local video = entry.videos[1]

        local file_name = video.filename
        video_data[file_name] = {
            vid_title = anime.name .. " - " .. theme.type .. (theme.sequence or ""),
            title = song and song.title or nil,
            artist = song and song.artists and song.artists[1] and song.artists[1].name or nil,
            source = anime.name .. " (" .. anime.year .. ")"
        }

        return video.link
    else
        msg.error("Failed to retrieve video details. API response: " .. (res.stdout or "N/A"))
        return nil
    end
end

function add_video_to_playlist()
    local video_url = get_video_details()
    if video_url then
        mp.commandv("loadfile", video_url, "append")
        msg.info("Added to playlist: " .. video_url)
    end
end

function display_video_info()
    local path = mp.get_property("path")
    msg.debug("Current path: " .. (path or "nil"))
    if path then
        local file_name = path:match("^.+/(.+)%.[^%.]+$")
        msg.debug("Extracted file name: " .. (file_name or "nil"))
        local data = video_data[file_name]
        msg.debug("Video data for file: " .. (data and "found" or "not found"))
        if data then
            local osd_text = string.format("%s\n%s", data.vid_title, data.source)
            if data.title then
                osd_text = osd_text .. string.format("\nSong: %s", data.title)
            end
            if data.artist then
                osd_text = osd_text .. string.format("\nArtist: %s", data.artist)
            end
            msg.debug("Displaying OSD text: " .. osd_text)
            mp.osd_message(osd_text, 7)
        else
            msg.debug("No video data available for display")
        end
    else
        msg.debug("No path available")
    end
end

function display_video_info_and_cleanup()
    display_video_info()
    local path = mp.get_property("path")
    if path then
        local file_name = path:match("^.+/(.+)%.[^%.]+$")
        if file_name and video_data[file_name] then
            video_data[file_name] = nil
            msg.debug("Removed video data for: " .. file_name)
        end
    end
end

function schedule_end_display()
    local duration = mp.get_property_number("duration")
    if duration then
        local time_to_end = duration - 5
        if time_to_end > 0 then
            mp.add_timeout(time_to_end, display_video_info_and_cleanup)
        else
            display_video_info_and_cleanup()
        end
    end
end

mp.register_event("file-loaded", schedule_end_display)

-- Add a couple videos to start
add_video_to_playlist()
add_video_to_playlist()

-- Set event listeners
mp.register_event("end-file", add_video_to_playlist)
mp.register_event("file-loaded", display_video_info)