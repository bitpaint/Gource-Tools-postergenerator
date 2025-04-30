gource -s 0.00001 --viewport 3840x2160 --stop-at-end --hide users,filenames,dirnames --output-ppm-stream - | ffmpeg -y -f image2pipe -vcodec ppm -i - -update 1 last_frame.png

