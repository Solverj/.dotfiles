#!/bin/bash
scrot /tmp/screen_locked.png
convert /tmp/screen_locked.png -blur 0x8 /tmp/screen_locked_blurred.png
rm /tmp/screen_locked.png
i3lock -i /tmp/screen_locked_blurred.png
