**_Render snapshots of data into a movie using Mathematica!_**

### Usage
```
./mathematica_movie.m [opts] <filename>
```
Given a collection of data files contained in the directory `filename`, render each data file into an image according to the rendering function `render` (with default location `render.m`) and sequence the images into a movie.

### Options
```
 -h            (Print this information)
 -g <header>   (Use given header instead of render.m)
 -p <n>        (Render frames in parallel using n procs)
 -w            (Render frames without making a movie)
 -j <n>        (Render every n frames)
 -n <n>        (Render up to n frames)
 ```
 
 ### Dependencies
- [Mathematica](http://www.wolfram.com/mathematica/)
- [FFmpeg](https://ffmpeg.org/)
