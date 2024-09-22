-- Lua script to autoplay videos from openings.moe using their API
local utils = require 'mp.utils'
local msg = require 'mp.msg'

-- Base URLs for the API and videos
local api_url = "https://openings.moe/api/details.php"
local video_base_url = "https://openings.moe/"

-- Initialize the index
local index = 1
math.randomseed(os.time())
local seed = math.random(1, 2 ^ 31 - 1)
local seed_b = math.random(1, 2 ^ 31 - 1)

-- Table to store video data
local video_data = {}
-- Function to get video details from the API
function get_video_details()
    local params = api_url
    if seed and seed_b then
        params = params .. "?strict=true&seed=" .. seed .. "&seed_b=" .. seed_b .. "&index_=" .. index
    end

    msg.info("Fetching video details" ..
                 (seed and (" with seed: " .. seed .. ", seed_b: " .. seed_b .. ", index: " .. index) or ""))
    msg.info("API URL: " .. params)
    local res = mp.command_native({
        name = "subprocess",
        args = {"curl", "-s", "-A", "mpv_openings_moe/1.0", params},
        capture_stdout = true,
        playback_only = false
    })

    local response = utils.parse_json(res.stdout)

    if response and response.data then
        -- Store the seeds from the API response
        seed = response.next.seed
        seed_b = response.next.seed_b
        index = response.next.index_

        local video_file = response.data.file
        local mime_types = response.data.mime
        local video_path = response.data.path

        -- Store video data
        local file_name = video_file -- This is the file name without extension
        video_data[file_name] = {
            vid_title = response.data.title,
            title = response.data.song and response.data.song.title or nil,
            artist = response.data.song and response.data.song.artist or nil,
            source = response.data.source
        }

        -- Prioritize the smallest available file (smallest MIME type first)
        if mime_types and #mime_types > 0 then
            local chosen_mime = mime_types[1]
            return video_path .. "/" .. video_file .. "." .. mime_extension(chosen_mime)
        else
            return video_path .. "/" .. video_file .. ".mp4" -- Default fallback if MIME type is missing
        end
    else
        msg.error("Failed to retrieve video details. API response: " .. (res.stdout or "N/A") .. ", Error: " ..
                      (res.stderr or "N/A") .. ", Exit code: " .. (res.status or "N/A"))
        return nil
    end
end

-- Function to map MIME type to file extension
function mime_extension(mime_type)
    if mime_type == "video/mp4" then
        return "mp4"
    elseif mime_type:find("webm") then
        return "webm"
    else
        return "mp4" -- Default to mp4 if unsure
    end
end

-- Function to add a video to the playlist
function add_video_to_playlist()
    local video_path = get_video_details()
    if video_path then
        local full_video_url = video_base_url .. video_path
        mp.commandv("loadfile", full_video_url, "append")
        msg.info("Added to playlist: " .. full_video_url)
    end
end

-- Function to display video information
function display_video_info()
    local path = mp.get_property("path")
    if path then
        local file_name = path:match("^.+/(.+)%.[^%.]+$")
        if file_name then
            local data = video_data[file_name]
            if data then
                local osd_text = string.format("%s\n%s\n%s", data.title or "", data.artist or "", data.source or "")
                mp.osd_message(osd_text, 5)
            else
                mp.osd_message("No information available", 2)
            end
        end
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
            local osd_text = string.format("%s %s", data.vid_title, data.source)
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

-- add a couple videos to start
add_video_to_playlist()
add_video_to_playlist()

-- Set event listeners
mp.register_event("end-file", add_video_to_playlist)
mp.register_event("file-loaded", display_video_info)
