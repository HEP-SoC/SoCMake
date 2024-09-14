#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <input.gif>"
  exit 1
fi

input_gif="$1"
output_mp4="${input_gif%.gif}.mp4"
temp_mp4="${input_gif%.gif}-temp.mp4"

# Convert GIF to temporary MP4
ffmpeg -i "$input_gif" "$temp_mp4"

# Fix the width/height issue and create the final MP4
ffmpeg -y -i "$temp_mp4" -c:v libx264 -c:a aac -strict experimental -tune fastdecode -pix_fmt yuv420p -b:a 192k -ar 48000 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" "$output_mp4"

# Remove temporary files
rm "$temp_mp4"

echo "Conversion complete. MP4 file: $output_mp4"
