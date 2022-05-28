Trimming video:
```
ffmpeg.exe -ss 00:42:37 -i ../Factorio/raw.mp4 -c copy -t 00:00:09 ../Factorio/output.mp4
```

Cropping video:
```
ffmpeg -i ../Factorio/output.mp4 -filter:v "crop=1200:800" ../Factorio/cropped.mp4
```