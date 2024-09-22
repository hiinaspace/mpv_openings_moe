# mpv_openings_moe.lua

A Lua script for MPV that automatically plays videos from <https://openings.moe> using their API.

## Usage

Download the script somewhere, then start MPV with the script explicitly:

```sh
   mpv --script=mpv_openings_moe.lua /dev/null
```

It'll play videos continuously, with some OSD text when you get a new video.

You probably don't want to autoload the script in the usual scripts directory
since it autoplays with no configuration to turn it off.
