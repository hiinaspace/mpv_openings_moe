# mpv_{openings,animethemes}_moe.lua

A Lua script for MPV that automatically plays random videos from <https://openings.moe> or <https://animethemes.moe> using their respective APIs.

I originally made the openings.moe script before I knew about animethemes.moe, but the latter seems
to have more videos, so they're both here.

## Usage

Download the scripts somewhere, then start MPV with the script explicitly:

For openings.moe:

```sh
mpv --script=mpv_openings_moe.lua /dev/null
```

For animethemes.moe:

```sh
mpv --script=mpv_animethemes_moe.lua /dev/null
```

It'll play videos continuously, with some OSD text when you get a new video.

You probably don't want to autoload the script in the usual scripts directory
since it autoplays with no configuration to turn it off.
