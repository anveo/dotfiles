#!/bin/bash

start_time=0:22
duration=2.5
scale=180
fps=15

palette="/tmp/palette.png"

filters="fps=$fps,scale=$scale:-1:flags=lanczos"

ffmpeg -v warning -ss $start_time -t $duration -i $1 -vf "$filters,palettegen" -y $palette
ffmpeg -v warning -ss $start_time -t $duration -i $1 -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y $2

